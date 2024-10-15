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
#if not CLEAN18
        FAExtPostingGr: Record "FA Extended Posting Group";
#endif
    begin
        with FALedgEntry do begin
            FAPostingGr.GetPostingGroup("FA Posting Group", "Depreciation Book Code");
            GLAccNo := '';
            if "FA Posting Category" = "FA Posting Category"::" " then
                case "FA Posting Type" of
                    "FA Posting Type"::"Acquisition Cost":
                        GLAccNo := FAPostingGr.GetAcquisitionCostAccount;
                    "FA Posting Type"::Depreciation:
                        GLAccNo := FAPostingGr.GetAccumDepreciationAccount;
                    "FA Posting Type"::"Write-Down":
                        GLAccNo := FAPostingGr.GetWriteDownAccount;
                    "FA Posting Type"::Appreciation:
                        GLAccNo := FAPostingGr.GetAppreciationAccount;
                    "FA Posting Type"::"Custom 1":
                        GLAccNo := FAPostingGr.GetCustom1Account;
                    "FA Posting Type"::"Custom 2":
                        GLAccNo := FAPostingGr.GetCustom2Account;
                    "FA Posting Type"::"Proceeds on Disposal":
#if not CLEAN18
                        // NAVCZ
                        if not FAPostingGr.UseStandardDisposal() then begin
                            FAExtPostingGr.Get(FAPostingGr.Code, 1, "Reason Code");
                            FAExtPostingGr.TestField("Sales Acc. On Disp. (Gain)");
                            GLAccNo := FAExtPostingGr."Sales Acc. On Disp. (Gain)";
                        end else
                            // NAVCZ
#endif
                        GLAccNo := FAPostingGr.GetSalesAccountOnDisposalGain;
                    "FA Posting Type"::"Gain/Loss":
                        begin
                            if "Result on Disposal" = "Result on Disposal"::Gain then
                                GLAccNo := FAPostingGr.GetGainsAccountOnDisposal;
                            if "Result on Disposal" = "Result on Disposal"::Loss then
                                GLAccNo := FAPostingGr.GetLossesAccountOnDisposal;
                        end;
                end;

            if "FA Posting Category" = "FA Posting Category"::Disposal then
                case "FA Posting Type" of
                    "FA Posting Type"::"Acquisition Cost":
                        GLAccNo := FAPostingGr.GetAcquisitionCostAccountOnDisposal;
                    "FA Posting Type"::Depreciation:
                        begin
#if not CLEAN18
                            // NAVCZ
                            if FAPostingGr.UseStandardDisposal() then
                                // NAVCZ
#endif
                            FAPostingGr.TestField("Accum. Depr. Acc. on Disposal");
                            GLAccNo := FAPostingGr."Accum. Depr. Acc. on Disposal";
                        end;
                    "FA Posting Type"::"Write-Down":
                        GLAccNo := FAPostingGr.GetWriteDownAccountOnDisposal;
                    "FA Posting Type"::Appreciation:
                        GLAccNo := FAPostingGr.GetAppreciationAccountOnDisposal;
                    "FA Posting Type"::"Custom 1":
                        GLAccNo := FAPostingGr.GetCustom1AccountOnDisposal;
                    "FA Posting Type"::"Custom 2":
                        GLAccNo := FAPostingGr.GetCustom2AccountOnDisposal;
                    "FA Posting Type"::"Book Value on Disposal":
                        begin
                            if "Result on Disposal" = "Result on Disposal"::Gain then
#if not CLEAN18
                                // NAVCZ
                                if not FAPostingGr.UseStandardDisposal() then begin
                                    FAExtPostingGr.Get(FAPostingGr.Code, 1, "Reason Code");
                                    FAExtPostingGr.TestField("Book Val. Acc. on Disp. (Gain)");
                                    GLAccNo := FAExtPostingGr."Book Val. Acc. on Disp. (Gain)";
                                end else
                                    // NAVCZ
#endif
                                    GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalGain;
                            if "Result on Disposal" = "Result on Disposal"::Loss then
#if not CLEAN18
                                // NAVCZ
                                if not FAPostingGr.UseStandardDisposal() then begin
                                    FAExtPostingGr.Get(FAPostingGr.Code, 1, "Reason Code");
                                    FAExtPostingGr.TestField("Book Val. Acc. on Disp. (Loss)");
                                    GLAccNo := FAExtPostingGr."Book Val. Acc. on Disp. (Loss)";
                                end else
                                    // NAVCZ
#endif
                                    GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalLoss;
                            "Result on Disposal" := "Result on Disposal"::" ";
                        end;
                end;

            if "FA Posting Category" = "FA Posting Category"::"Bal. Disposal" then
                case "FA Posting Type" of
                    "FA Posting Type"::"Write-Down":
                        GLAccNo := FAPostingGr.GetWriteDownBalAccountOnDisposal;
                    "FA Posting Type"::Appreciation:
                        GLAccNo := FAPostingGr.GetAppreciationBalAccountOnDisposal;
                    "FA Posting Type"::"Custom 1":
                        GLAccNo := FAPostingGr.GetCustom1BalAccountOnDisposal;
                    "FA Posting Type"::"Custom 2":
                        GLAccNo := FAPostingGr.GetCustom2BalAccountOnDisposal;
                end;
        end;

        OnAfterGetAccNo(FALedgEntry, GLAccNo);
        exit(GLAccNo);
    end;

    procedure GetMaintenanceAccNo(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"): Code[20]
#if not CLEAN18
    var
        FAExtPostingGr: Record "FA Extended Posting Group";
#endif
    begin
        FAPostingGr.GetPostingGroup(
            MaintenanceLedgEntry."FA Posting Group", MaintenanceLedgEntry."Depreciation Book Code");
#if not CLEAN18
        // NAVCZ
        if not FAPostingGr.UseStandardMaintenance() then begin
            FAExtPostingGr.Get(MaintenanceLedgEntry."FA Posting Group", 2, MaintenanceLedgEntry."Maintenance Code");
            FAExtPostingGr.TestField("Maintenance Expense Account");
            exit(FAExtPostingGr."Maintenance Expense Account");
        end;
        // NAVCZ
#endif
        exit(FAPostingGr.GetMaintenanceExpenseAccount);
    end;

#if not CLEAN18
    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure GetCorrespondAccNo(var FALedgEntry: Record "FA Ledger Entry"): Code[20]
    begin
        // NAVCZ
        with FALedgEntry do begin
            FAPostingGr.Get("FA Posting Group");
            GLAccNo := '';
            case "FA Posting Type" of
                "FA Posting Type"::"Acquisition Cost":
                    GLAccNo := FAPostingGr.GetAcquisitionCostBalanceAccountOnDisposal;
                "FA Posting Type"::"Write-Down":
                    GLAccNo := FAPostingGr.GetWriteDownBalAccountOnDisposal;
                "FA Posting Type"::Appreciation:
                    GLAccNo := FAPostingGr.GetAppreciationBalAccountOnDisposal;
                "FA Posting Type"::"Custom 1":
                    GLAccNo := FAPostingGr.GetCustom1BalAccountOnDisposal;
                "FA Posting Type"::"Custom 2":
                    GLAccNo := FAPostingGr.GetCustom2BalAccountOnDisposal;
                "FA Posting Type"::"Book Value on Disposal":
                    GLAccNo := FAPostingGr.GetBookValueBalAccountOnDisposal;
            end;
        end;
        exit(GLAccNo);
        // NAVCZ
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccNo(var FALedgEntry: Record "FA Ledger Entry"; var GLAccNo: Code[20])
    begin
    end;
}

