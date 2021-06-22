codeunit 5349 "Auto Create Sales Orders"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
        CreateNAVSalesOrdersFromSubmittedCRMSalesorders;
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        StartingToCreateSalesOrderTelemetryMsg: Label 'Job queue entry starting to create sales order from %1 order %2.', Locked = true;
        CommittingAfterCreateSalesOrderTelemetryMsg: Label 'Job queue entry committing after processing %1 order %2.', Locked = true;

    local procedure CreateNAVSalesOrdersFromSubmittedCRMSalesorders()
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        CRMSalesorder.SetRange(StateCode, CRMSalesorder.StateCode::Submitted);
        CRMSalesorder.SetRange(LastBackofficeSubmit, 0D);
        if CRMSalesorder.FindSet(true) then
            repeat
                SendTraceTag('0000DET', CrmTelemetryCategoryTok, VERBOSITY::Normal,
                    StrSubstNo(StartingToCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), DATACLASSIFICATION::SystemMetadata);
                if CODEUNIT.Run(CODEUNIT::"CRM Sales Order to Sales Order", CRMSalesorder) then begin
                    SendTraceTag('0000DEU', CrmTelemetryCategoryTok, VERBOSITY::Normal,
                        StrSubstNo(CommittingAfterCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), DATACLASSIFICATION::SystemMetadata);
                    Commit();
                end;
            until CRMSalesorder.Next = 0;
    end;
}

