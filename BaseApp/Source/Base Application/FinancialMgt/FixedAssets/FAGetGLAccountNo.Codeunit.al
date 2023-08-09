codeunit 5602 "FA Get G/L Account No."
{

    trigger OnRun()
    begin
    end;

    var
        FAPostingGr: Record "FA Posting Group";
        GLAccNo: Code[20];

    procedure GetAccNo(var FALedgEntry: Record "FA Ledger Entry"): Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        with FALedgEntry do begin
            FAPostingGr.GetPostingGroup("FA Posting Group", "Depreciation Book Code");
            OnGetAccNoOnAfterGetFAPostingGroup(FAPostingGr, FALedgEntry, GLAccNo, IsHandled);
            if IsHandled then
                exit(GLAccNo);
            GLAccNo := '';
            if "FA Posting Category" = "FA Posting Category"::" " then
                case "FA Posting Type" of
                    "FA Posting Type"::"Acquisition Cost":
                        GLAccNo := FAPostingGr.GetAcquisitionCostAccount();
                    "FA Posting Type"::Depreciation:
                        GLAccNo := FAPostingGr.GetAccumDepreciationAccount();
                    "FA Posting Type"::"Write-Down":
                        GLAccNo := FAPostingGr.GetWriteDownAccount();
                    "FA Posting Type"::Appreciation:
                        GLAccNo := FAPostingGr.GetAppreciationAccount();
                    "FA Posting Type"::"Custom 1":
                        GLAccNo := FAPostingGr.GetCustom1Account();
                    "FA Posting Type"::"Custom 2":
                        GLAccNo := FAPostingGr.GetCustom2Account();
                    "FA Posting Type"::"Proceeds on Disposal":
                        GLAccNo := FAPostingGr.GetSalesAccountOnDisposalGain();
                    "FA Posting Type"::"Gain/Loss":
                        begin
                            if "Result on Disposal" = "Result on Disposal"::Gain then
                                GLAccNo := FAPostingGr.GetGainsAccountOnDisposal();
                            if "Result on Disposal" = "Result on Disposal"::Loss then
                                GLAccNo := FAPostingGr.GetLossesAccountOnDisposal();
                        end;
                end;

            if "FA Posting Category" = "FA Posting Category"::Disposal then
                case "FA Posting Type" of
                    "FA Posting Type"::"Acquisition Cost":
                        GLAccNo := FAPostingGr.GetAcquisitionCostAccountOnDisposal();
                    "FA Posting Type"::Depreciation:
                        GLAccNo := FAPostingGr.GetAccumDepreciationAccountOnDisposal();
                    "FA Posting Type"::"Write-Down":
                        GLAccNo := FAPostingGr.GetWriteDownAccountOnDisposal();
                    "FA Posting Type"::Appreciation:
                        GLAccNo := FAPostingGr.GetAppreciationAccountOnDisposal();
                    "FA Posting Type"::"Custom 1":
                        GLAccNo := FAPostingGr.GetCustom1AccountOnDisposal();
                    "FA Posting Type"::"Custom 2":
                        GLAccNo := FAPostingGr.GetCustom2AccountOnDisposal();
                    "FA Posting Type"::"Book Value on Disposal":
                        begin
                            if "Result on Disposal" = "Result on Disposal"::Gain then
                                GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalGain();
                            if "Result on Disposal" = "Result on Disposal"::Loss then
                                GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalLoss();
                            "Result on Disposal" := "Result on Disposal"::" ";
                        end;
                end;

            if "FA Posting Category" = "FA Posting Category"::"Bal. Disposal" then
                case "FA Posting Type" of
                    "FA Posting Type"::"Write-Down":
                        GLAccNo := FAPostingGr.GetWriteDownBalAccountOnDisposal();
                    "FA Posting Type"::Appreciation:
                        GLAccNo := FAPostingGr.GetAppreciationBalAccountOnDisposal();
                    "FA Posting Type"::"Custom 1":
                        GLAccNo := FAPostingGr.GetCustom1BalAccountOnDisposal();
                    "FA Posting Type"::"Custom 2":
                        GLAccNo := FAPostingGr.GetCustom2BalAccountOnDisposal();
                end;
        end;

        OnAfterGetAccNo(FALedgEntry, GLAccNo);
        exit(GLAccNo);
    end;

    procedure GetMaintenanceAccNo(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"): Code[20]
    begin
        FAPostingGr.GetPostingGroup(
            MaintenanceLedgEntry."FA Posting Group", MaintenanceLedgEntry."Depreciation Book Code");
        exit(FAPostingGr.GetMaintenanceExpenseAccount());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccNo(var FALedgEntry: Record "FA Ledger Entry"; var GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccNoOnAfterGetFAPostingGroup(var FAPostingGr: Record "FA Posting Group"; FALedgerEntry: Record "FA Ledger Entry"; var GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

