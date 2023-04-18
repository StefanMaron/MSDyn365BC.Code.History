query 133 "Inc. Doc. Atts. Ready for OCR"
{
    Caption = 'Inc. Doc. Atts. Ready for OCR';

    elements
    {
        dataitem(Incoming_Document; "Incoming Document")
        {
            DataItemTableFilter = "OCR Status" = CONST(Ready);
            dataitem(Incoming_Document_Attachment; "Incoming Document Attachment")
            {
                DataItemLink = "Incoming Document Entry No." = Incoming_Document."Entry No.";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = "Use for OCR" = CONST(true);
                column(Incoming_Document_Entry_No; "Incoming Document Entry No.")
                {
                }
                column(Line_No; "Line No.")
                {
                }
            }
        }
    }
}

