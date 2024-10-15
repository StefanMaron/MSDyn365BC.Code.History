page 18321 "GST Settlement"
{
    Caption = 'GST Settlement';
    UsageCategory = Documents;
    ApplicationArea = Basic, Suite;
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("GSTINNo."; GSTINNo)
                {
                    Caption = 'GST Registration No.';
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "GST Registration Nos.";
                    ShowMandatory = true;
                    TableRelation = "GST Registration Nos." WHERE("Input Service Distributor" = CONST(false));
                    Tooltip = 'Specifies GST registration number to discharge the tax liability to the government.';

                    trigger OnValidate()
                    var
                        GSTRegistrationNos: Record "GST Registration Nos.";
                    begin
                        GSTRegistrationNos.Get(GSTINNo);
                        if GSTRegistrationNos."Input Service Distributor" then
                            Error(ISDGSTRegNoErr);
                        EnableApplyEntries();
                    end;
                }
                field("Posting Date"; PostingDate)
                {
                    Caption = 'Posting Date';
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Tooltip = 'Specifies GST settlement date.';

                    trigger OnValidate()
                    begin
                        DateFilter := '';
                        if PostingDate <> 0D then begin
                            IsPostingDateAllowed();
                            DateFilter := '..' + Format(GSTSettlement.GetPeriodEndDate(PostingDate));
                        end;
                        EnableApplyEntries();
                    end;
                }
                field(AccountType; AccountType)
                {
                    Caption = 'Account Type';
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'G/L Account","Bank Account';
                    Tooltip = 'Specifies whether account type is G/L account or bank account.';

                    trigger OnValidate()
                    begin
                        AccountNo := '';
                    end;
                }
                field("Account No"; AccountNo)
                {
                    Caption = 'Account No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies account number as selected in account type.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccount: Record "G/L Account";
                        BankAccount: Record "Bank Account";
                        GLAccountList: Page "G/L Account List";
                        BankAccountList: Page "Bank Account List";
                    begin
                        if AccountType = AccountType::"G/L Account" then begin
                            GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                            GLAccount.SetRange(Blocked, FALSE);
                            GLAccountList.SetTableView(GLAccount);
                            GLAccountList.LookupMode := true;
                            if GLAccountList.RunModal() = Action::LookupOK then begin
                                GLAccountList.GetRecord(GLAccount);
                                GSTPaymentBuffer.CheckGLAcc(GLAccount."No.");
                                AccountNo := GLAccount."No.";
                            end;
                        end else begin
                            BankAccount.SetRange(Blocked, FALSE);
                            BankAccountList.SetTableView(BankAccount);
                            BankAccountList.LookupMode := TRUE;
                            if BankAccountList.RunModal() = Action::LookupOK then begin
                                BankAccountList.GetRecord(BankAccount);
                                GSTPaymentBuffer.CheckBank(BankAccount."No.");
                                AccountNo := BankAccount."No.";
                            end;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if AccountType = AccountType::"G/L Account" then
                            GSTPaymentBuffer.CheckGLAcc(AccountNo)
                        else
                            GSTPaymentBuffer.CheckBank(AccountNo);
                    end;
                }
                field("BankReference No"; BankReferenceNo)
                {
                    Caption = 'Bank Reference No.';
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies bank reference number.';
                }
                field("Bank Reference Date"; BankReferenceDate)
                {
                    Caption = 'Bank Reference Date';
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies bank reference date.';
                }
                field("Date Filter"; DateFilter)
                {
                    Caption = 'Date Filter';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies date filter.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(ApplyEntries)
            {
                Caption = 'Apply Entries';
                ApplicationArea = Basic, Suite;
                Enabled = ApplyBtnEnable;
                Image = Payment;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Shift+F11';
                ToolTip = 'Apply the amount on journal line to the relevant posted entry, this updated the posted document.';

                trigger OnAction()
                begin
                    GSTSettlement.ApplyGSTSettlement(GSTINNo, PostingDate, AccountType, AccountNo, BankReferenceNo, BankReferenceDate);
                    CurrPage.CLOSE();
                end;
            }
        }
    }

    var
        GSTPaymentBuffer: Record "GST Payment Buffer";
        GSTSettlement: Codeunit "GST Settlement";
        GSTINNo: Code[20];
        PostingDate: Date;
        ApplyBtnEnable: Boolean;
        AccountNo: Code[20];
        AccountType: Option "G/L Account","Bank Account";
        BankReferenceNo: Code[10];
        BankReferenceDate: Date;
        DateFilter: Text[30];
        PostingDateErr: Label 'Posting date must be after %1. Settlement cannot be posted in already settled period.', Comment = '%1 = Date Filter';
        ISDGSTRegNoErr: Label 'You must select GST Registration No. that has ISD set to False.';

    local procedure EnableApplyEntries()
    begin
        ApplyBtnEnable := (GSTINNo <> '') AND (PostingDate <> 0D);
        CurrPage.UPDATE();
    end;

    local procedure IsPostingDateAllowed()
    var
        PostedSettlementEntries: Record "Posted Settlement Entries";
    begin
        PostedSettlementEntries.SetRange("GST Registration No.", GSTINNo);
        if PostedSettlementEntries.FINDLAST() then begin
            if (Date2DMY(PostingDate, 2) < Date2DMY(PostedSettlementEntries."Posting Date", 2)) AND
               (Date2DMY(PostingDate, 3) = Date2DMY(PostedSettlementEntries."Posting Date", 3))
            then
                ERROR(PostingDateErr, PostedSettlementEntries."Period End Date");

            if Date2DMY(PostingDate, 3) < Date2DMY(PostedSettlementEntries."Posting Date", 3) then
                ERROR(PostingDateErr, PostedSettlementEntries."Period End Date");
        end;
    end;
}

