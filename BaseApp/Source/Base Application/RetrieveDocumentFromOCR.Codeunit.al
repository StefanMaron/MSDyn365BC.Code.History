codeunit 135 "Retrieve Document From OCR"
{
    TableNo = "Incoming Document";

    trigger OnRun()
    var
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        SendIncomingDocumentToOCR.RetrieveDocFromOCR(Rec);
    end;
}

