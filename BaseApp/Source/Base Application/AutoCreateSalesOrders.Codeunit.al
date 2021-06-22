codeunit 5349 "Auto Create Sales Orders"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
        CreateNAVSalesOrdersFromSubmittedCRMSalesorders;
    end;

    local procedure CreateNAVSalesOrdersFromSubmittedCRMSalesorders()
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        CRMSalesorder.SetRange(StateCode, CRMSalesorder.StateCode::Submitted);
        CRMSalesorder.SetRange(LastBackofficeSubmit, 0D);
        if CRMSalesorder.FindSet(true) then
            repeat
                if CODEUNIT.Run(CODEUNIT::"CRM Sales Order to Sales Order", CRMSalesorder) then
                    Commit();
            until CRMSalesorder.Next = 0;
    end;
}

