-- Mizan migration
-- id: 20260828150000_crm_quote_approval_history.sql
-- owner: crm-and-cpq
-- prerequisites: 20260827260000_crm_360_health_cpq.sql
-- changes: quote approval submission and customer interaction history RPC
-- security: authenticated tenant scope, maker-checker approval, read-only history, and restricted grants
-- verification: supabase/tests/20260828150000_crm_quote_approval_history.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

alter table public.approval_requests drop constraint if exists approval_requests_request_type_check;
alter table public.approval_requests add constraint approval_requests_request_type_check check (request_type in ('expense','invoice','bill','journal','balance_adjustment','refund','discount','period_reopen','purchase_requisition','purchase_order','quote'));

create or replace function public.approval_decision_permission(p_tenant_id uuid,p_request_type text)
returns boolean language sql stable security definer set search_path=public as $$
 select public.is_tenant_owner(p_tenant_id)
   or public.has_tenant_permission(p_tenant_id,array['approveRequests','manageSettings'])
   or case p_request_type
     when 'journal' then public.has_tenant_permission(p_tenant_id,array['manageAccounting','postJournalEntries'])
     when 'invoice' then public.has_tenant_permission(p_tenant_id,array['manageInvoices','manageSettings'])
     when 'bill' then public.has_tenant_permission(p_tenant_id,array['manageBills','manageSettings'])
     when 'balance_adjustment' then public.has_tenant_permission(p_tenant_id,array['manageAccounting','manageSettings'])
     when 'purchase_requisition' then public.has_tenant_permission(p_tenant_id,array['approveProcurement','manageProcurement'])
     when 'purchase_order' then public.has_tenant_permission(p_tenant_id,array['approveProcurement','manageProcurement'])
     when 'quote' then public.has_tenant_permission(p_tenant_id,array['manageCrm','manageInvoices','manageSettings'])
     else false end;
$$;

create or replace function public.create_approval_request(p_tenant_id uuid,p_request_type text,p_target_id uuid default null,p_payload jsonb default '{}'::jsonb,p_amount_minor bigint default 0,p_currency_code text default 'YER',p_reason text default '',p_branch_id uuid default null,p_idempotency_key text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user_id uuid:=auth.uid(); v_request public.approval_requests;
begin
 if v_user_id is null or not public.is_tenant_member(p_tenant_id) then raise exception 'Authenticated tenant membership required'; end if;
 if not public.approval_branch_access(p_tenant_id,p_branch_id) then raise exception 'Branch access required'; end if;
 if p_request_type not in ('expense','invoice','bill','journal','balance_adjustment','refund','discount','period_reopen','purchase_requisition','purchase_order','quote') then raise exception 'Approval request type is invalid'; end if;
 if p_amount_minor is null or p_amount_minor<0 then raise exception 'Approval amount must be non-negative'; end if;
 if p_currency_code is null or p_currency_code<>upper(btrim(p_currency_code)) or length(btrim(p_currency_code)) not between 3 and 5 then raise exception 'Approval currency code is invalid'; end if;
 if p_reason is null or length(btrim(p_reason)) not between 1 and 1000 then raise exception 'Approval reason is required'; end if;
 if p_idempotency_key is not null and length(btrim(p_idempotency_key)) not between 8 and 200 then raise exception 'Approval idempotency key is invalid'; end if;
 if p_idempotency_key is not null then select * into v_request from public.approval_requests where tenant_id=p_tenant_id and requester_id=v_user_id and idempotency_key=btrim(p_idempotency_key) limit 1; if found then return to_jsonb(v_request); end if; end if;
 insert into public.approval_requests(tenant_id,requester_id,request_type,target_id,payload,amount_minor,currency_code,reason,branch_id,idempotency_key) values(p_tenant_id,v_user_id,p_request_type,p_target_id,coalesce(p_payload,'{}'::jsonb),p_amount_minor,upper(btrim(p_currency_code)),btrim(p_reason),p_branch_id,nullif(btrim(p_idempotency_key),'')) returning * into v_request;
 insert into public.approval_request_events(tenant_id,approval_request_id,actor_id,from_status,to_status,decision_reason) values(p_tenant_id,v_request.id,v_user_id,null,'pending',v_request.reason);
 return to_jsonb(v_request);
end;$$;
create or replace function public.submit_crm_quote_for_approval(p_quote_id uuid,p_reason text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_tenant uuid:=public.current_tenant_id(); v_quote public.crm_quotes; v_approval jsonb;
begin
 if auth.uid() is null or v_tenant is null then raise exception 'Authenticated tenant membership required'; end if;
 if not public.has_tenant_permission(v_tenant,array['manageCrm','manageInvoices','manageSettings']) then raise exception 'Quote approval permission required'; end if;
 select * into v_quote from public.crm_quotes where id=p_quote_id and tenant_id=v_tenant for update;
 if not found or v_quote.status<>'draft' then raise exception 'Only draft quotes can be submitted'; end if;
 v_approval:=public.create_approval_request(v_tenant,'quote',v_quote.id,jsonb_build_object('quote_id',v_quote.id,'quote_number',v_quote.quote_number,'total_minor',v_quote.total_minor,'currency_code',v_quote.currency_code),v_quote.total_minor,v_quote.currency_code,coalesce(nullif(btrim(p_reason),''),'Quote approval'),null,null);
 update public.crm_quotes set status='sent' where id=v_quote.id and tenant_id=v_tenant;
 return v_approval||jsonb_build_object('quote_id',v_quote.id);
end;$$;
create or replace function public.list_crm_interactions(p_entity_type text,p_entity_id uuid)
returns table(id uuid,channel text,direction text,summary text,occurred_at timestamptz,created_by uuid)
language sql stable security definer set search_path=public as $$ select i.id,i.channel,i.direction,i.summary,i.occurred_at,i.created_by from public.crm_interactions i where i.tenant_id=public.current_tenant_id() and public.is_tenant_member(i.tenant_id) and i.entity_type=btrim(p_entity_type) and i.entity_id=p_entity_id order by i.occurred_at desc,i.id desc; $$;
revoke all on function public.submit_crm_quote_for_approval(uuid,text) from public,anon,authenticated; grant execute on function public.submit_crm_quote_for_approval(uuid,text) to authenticated;
revoke all on function public.list_crm_interactions(text,uuid) from public,anon,authenticated; grant execute on function public.list_crm_interactions(text,uuid) to authenticated;

create or replace function public.sync_crm_quote_approval_state() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.request_type='quote' then
   update public.crm_quotes set status=case when new.status='approved' then 'accepted' when new.status='rejected' then 'rejected' else status end where id=new.target_id and tenant_id=new.tenant_id and status='sent';
 end if;
 return new;
end;$$;
drop trigger if exists approval_requests_crm_quote_state on public.approval_requests;
create trigger approval_requests_crm_quote_state after update of status on public.approval_requests for each row execute function public.sync_crm_quote_approval_state();
