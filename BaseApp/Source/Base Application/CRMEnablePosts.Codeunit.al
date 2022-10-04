codeunit 5353 "CRM Enable Posts"
{

    trigger OnRun()
    begin
        if EnableActivityFeedsOnCRMOrders() then;
    end;

    var
        CRMOrderEntityNameTxt: Label 'salesorder', Locked = true;

    [TryFunction]
    local procedure EnableActivityFeedsOnCRMOrders()
    var
        CRMPostConfiguration: Record "CRM Post Configuration";
    begin
        with CRMPostConfiguration do begin
            SetRange(msdyn_EntityName, CRMOrderEntityNameTxt);
            if FindFirst() then begin
                if (statecode = statecode::Active) and (statuscode = statuscode::Active) and msdyn_ConfigureWall then
                    exit;
                statecode := statecode::Active;
                statuscode := statuscode::Active;
                msdyn_ConfigureWall := true;
                if Modify() then;
            end
        end;
    end;
}

