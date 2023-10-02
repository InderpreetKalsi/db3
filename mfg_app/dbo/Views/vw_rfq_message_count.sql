CREATE VIEW dbo.vw_rfq_message_count
AS
select mess.RFQ_ID
       , mess.MESSAGE_TYPE_ID
       , mess.MESSAGE_READ
       , case when (rfq.CONTact_ID = mess.TO_CONT
                   and (mess.EXPIRATION_DATE is null
                       or messageStatusRecipient.MESSAGE_STATUS_ID != 3))
               then messageStatusRecipient.MESSAGE_STATUS_ID
               -- detect expired quotes (=closed message status)
               when (rfq.CONTact_ID = mess.TO_CONT
                   and messageStatusRecipient.MESSAGE_STATUS_ID = 3
                   and mess.EXPIRATION_DATE < getdate())
               then 6
               when (rfq.CONTact_ID = mess.TO_CONT)
               then messageStatusRecipient.MESSAGE_STATUS_ID 
               when (rfq.CONTact_ID = mess.FROM_CONT    
                   and (mess.EXPIRATION_DATE is null
                       or messageStatusAuthor.MESSAGE_STATUS_ID != 3))                    
               then messageStatusAuthor.MESSAGE_STATUS_ID
               -- detect expired quotes (=closed message status)
               when (rfq.CONTact_ID = mess.FROM_CONT                     
                   and messageStatusAuthor.MESSAGE_STATUS_ID = 3
                   and mess.EXPIRATION_DATE < getdate())
               then 6
               when (rfq.CONTact_ID = mess.FROM_CONT)
               then messageStatusAuthor.MESSAGE_STATUS_ID 
               else 0
           end as MESSAGE_STATUS_ID_BUYER
       , count(*) as MESSAGE_COUNT
   from  dbo.mp_RFQ(nolock) as rfq
       inner join [dbo].mp_MESSAGEs(nolock) as mess 
           on rfq.RFQ_ID = mess.RFQ_ID            
       inner join dbo.mP_mst_MESSAGE_STATUS(nolock) messageStatusRecipient 
           on messageStatusRecipient.MESSAGE_STATUS_ID = mess.MESSAGE_STATUS_ID_RECIPIENT
       inner join dbo.mp_mst_MESSAGE_STATUS(nolock) messageStatusAuthor 
           on messageStatusAuthor.MESSAGE_STATUS_ID = mess.MESSAGE_STATUS_ID_AUTHOR
       INNER JOIN dbo.mP_CONTacts(NOLOCK) ct ON ct.CONTact_ID=mess.FROM_CONT
       INNER JOIN dbo.mP_COMPANies(NOLOCK) cp ON cp.COMPany_ID = ct.COMPany_ID

   where (mess.MESSAGE_TYPE_ID != 5)
       or 
       -- free RFX messages (5) for buyer : only count received messages
       (rfq.CONTact_ID = mess.TO_CONT)
       AND cp.sales_status_id<>2
   group by  mess.RFQ_ID
       , mess.MESSAGE_TYPE_ID    
       , mess.MESSAGE_READ    
       , case when (rfq.CONTact_ID = mess.TO_CONT
                   and (mess.EXPIRATION_DATE is null
                       or messageStatusRecipient.MESSAGE_STATUS_ID != 3))
               then messageStatusRecipient.MESSAGE_STATUS_ID
               -- detect expired quotes (=closed message status)
               when (rfq.CONTact_ID = mess.TO_CONT
                   and messageStatusRecipient.MESSAGE_STATUS_ID = 3
                   and mess.EXPIRATION_DATE < getdate())
               then 6
               when (rfq.CONTact_ID = mess.TO_CONT)
               then messageStatusRecipient.MESSAGE_STATUS_ID 
               when (rfq.CONTact_ID = mess.FROM_CONT    
                   and (mess.EXPIRATION_DATE is null
                       or messageStatusAuthor.MESSAGE_STATUS_ID != 3))                    
               then messageStatusAuthor.MESSAGE_STATUS_ID
               -- detect expired quotes (=closed message status)
               when (rfq.CONTact_ID = mess.FROM_CONT                     
                   and messageStatusAuthor.MESSAGE_STATUS_ID = 3
                   and mess.EXPIRATION_DATE < getdate())
               then 6
               when (rfq.CONTact_ID = mess.FROM_CONT)
               then messageStatusAuthor.MESSAGE_STATUS_ID 
               else 0
           end
