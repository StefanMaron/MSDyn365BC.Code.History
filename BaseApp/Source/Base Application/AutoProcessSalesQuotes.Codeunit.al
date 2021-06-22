codeunit 5354 "Auto Process Sales Quotes"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
        CreateNAVSalesQuotesFromSubmittedCRMSalesquotes;
    end;

    local procedure CreateNAVSalesQuotesFromSubmittedCRMSalesquotes()
    var
        CRMQuote: Record "CRM Quote";
    begin
        CRMQuote.SetFilter(StateCode, '%1|%2', CRMQuote.StateCode::Active, CRMQuote.StateCode::Won);
        if CRMQuote.FindSet(true) then
            repeat
                if CODEUNIT.Run(CODEUNIT::"CRM Quote to Sales Quote", CRMQuote) then
                    Commit();
            until CRMQuote.Next = 0;
    end;
}

