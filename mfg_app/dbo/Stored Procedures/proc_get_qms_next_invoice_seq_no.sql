
/*
select * from mp_qms_quote_invoices
select * from mp_contacts where contact_id = 1337894

declare @invoicenextseqno bigint
exec proc_get_qms_next_invoice_seq_no 
@company_id = 1768057
,@invoice_next_seq_no = @invoicenextseqno output

select @invoicenextseqno

		select invoice_no , b.company_id , qms_quote_invoice_id , row_number () over (partition by b.company_id  order by  b.company_id ,  qms_quote_invoice_id) + 1000 rn 
		from mp_qms_quote_invoices (nolock) a
		join mp_contacts (nolock) b on a.created_by = b.contact_id 


*/

CREATE procedure proc_get_qms_next_invoice_seq_no
(@company_id int, @invoice_next_seq_no bigint output)
as
begin

	/* M2-2413 M - Invoice Starting Number modal - DB */ 
	set nocount on

	declare @row_count int 

	set @row_count = 
	(	select count(1)  invoice_no 
		from mp_qms_quote_invoices (nolock) a
		join mp_contacts (nolock) b on a.created_by = b.contact_id 
		where b.company_id = @company_id
	)

	if (@row_count > 0 )
	begin

		set @invoice_next_seq_no = 
		(
			select max(convert(bigint,invoice_no)) + 1  invoice_no 
			from mp_qms_quote_invoices (nolock) a
			join mp_contacts (nolock) b on a.created_by = b.contact_id 
			where b.company_id = @company_id 
		)
	end
	else
	begin
		set @invoice_next_seq_no = (select invoice_starting_seq_no from mp_qms_invoice_seq_no where company_id = @company_id)
	end


end
