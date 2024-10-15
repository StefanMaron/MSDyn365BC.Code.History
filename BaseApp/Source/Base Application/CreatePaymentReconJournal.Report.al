report 11701 "Create Payment Recon. Journal"
{
    Caption = 'Create Payment Recon. Journal';
    Permissions = TableData "Issued Bank Statement Header" = m;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Issued Bank Statement Header"; "Issued Bank Statement Header")
        {
            RequestFilterFields = "No.";
            dataitem("Issued Bank Statement Line"; "Issued Bank Statement Line")
            {
                DataItemLink = "Bank Statement No." = FIELD("No.");
                DataItemTableView = SORTING("Bank Statement No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if not HideMessages then
                        Window.Update(1, "Line No.");

                    CreateBankAccReconLine("Issued Bank Statement Header", "Issued Bank Statement Line");
                end;

                trigger OnPostDataItem()
                begin
                    if not HideMessages then
                        Window.Close;

                    MatchBankPmtApplication("Issued Bank Statement Header"."Bank Account No.", "Issued Bank Statement Header"."No.");
                end;

                trigger OnPreDataItem()
                begin
                    if not HideMessages then
                        Window.Open(CreatingLinesMsg);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CheckPmtReconExist;

                CreateBankAccRecon("Issued Bank Statement Header");
                UpdatePaymentReconciliationStatus("Payment Reconciliation Status"::Opened);
            end;

            trigger OnPostDataItem()
            begin
                if not HideMessages then
                    Message(SuccessCreatedMsg);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VariableToDescription; VariableToDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Variable S. to Description';
                        ToolTip = 'Specifies if variable symbol will be transferred to description';
                    }
                    field(VariableToVariable; VariableToVariable)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Variable S. to Variable S.';
                        ToolTip = 'Specifies if variable symbol will be transferred to variable symbol';
                    }
                    field(VariableToExtDocNo; VariableToExtDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Variable S. to External Doc. No.';
                        ToolTip = 'Specifies if variable symbol will be transferred to external doc. No.';
                    }
                    field(RunApplAutomatically; RunApplAutomatically)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Run Apply Automatically';
                        Description = 'CZ-Apply';
                        ToolTip = 'Specifies if Apply Automatically function is started after Payment Recon.Journal creating.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GetParameters;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            GetParameters;
    end;

    var
        Window: Dialog;
        VariableToDescription: Boolean;
        VariableToVariable: Boolean;
        VariableToExtDocNo: Boolean;
        CreatingLinesMsg: Label 'Creating payment reconciliation journal lines...\\Line No. #1##########', Comment = 'Progress bar';
        SuccessCreatedMsg: Label 'Payment Reconciliation Journal Lines was successfully created.';
        RunApplAutomatically: Boolean;
        HideMessages: Boolean;

    procedure SetHideMessages(HideMessagesNew: Boolean)
    begin
        HideMessages := HideMessagesNew;
    end;

    local procedure GetParameters()
    var
        BankAcc: Record "Bank Account";
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
        BankStmtNo: Code[20];
    begin
        BankStmtNo := CopyStr("Issued Bank Statement Header".GetFilter("No."), 1, MaxStrLen(BankStmtNo));
        if BankStmtNo = '' then
            exit;

        IssuedBankStmtHdr.Get(BankStmtNo);
        if BankAcc.Get(IssuedBankStmtHdr."Bank Account No.") then begin
            VariableToDescription := BankAcc."Variable S. to Description";
            VariableToVariable := BankAcc."Variable S. to Variable S.";
            VariableToExtDocNo := BankAcc."Variable S. to Ext. Doc.No.";
            RunApplAutomatically := BankAcc."Run Apply Automatically";
        end;
    end;

    local procedure CreateBankAccRecon(IssuedBankStmtHdr: Record "Issued Bank Statement Header")
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
    begin
        IssuedBankStmtHdr.CalcFields(Amount);
        with BankAccRecon do begin
            Init;
            "Statement Type" := "Statement Type"::"Payment Application";
            "Bank Account No." := IssuedBankStmtHdr."Bank Account No.";
            "Statement No." := IssuedBankStmtHdr."No.";
            "Statement Date" := IssuedBankStmtHdr."Document Date";
            "Statement Ending Balance" := IssuedBankStmtHdr.Amount;
            "Created From Iss. Bank Stat." := true;
            Insert(true);
        end;
    end;

    local procedure CreateBankAccReconLine(IssuedBankStmtHdr: Record "Issued Bank Statement Header"; IssuedBankStmtLn: Record "Issued Bank Statement Line")
    var
        BankAccReconLn: Record "Bank Acc. Reconciliation Line";
    begin
        with BankAccReconLn do begin
            Init;
            "Statement Type" := "Statement Type"::"Payment Application";
            "Transaction Date" := IssuedBankStmtHdr."Document Date";
            "Bank Account No." := IssuedBankStmtHdr."Bank Account No.";
            "Statement No." := IssuedBankStmtHdr."No.";
            "Statement Line No." := IssuedBankStmtLn."Line No.";
            if (IssuedBankStmtLn."Currency Code" = '') and (IssuedBankStmtLn."Bank Statement Currency Code" <> '') then begin
                Validate("Statement Amount", IssuedBankStmtLn."Amount (Bank Stat. Currency)");
                Validate("Currency Code", IssuedBankStmtLn."Bank Statement Currency Code");
                Validate("Currency Factor", IssuedBankStmtLn."Bank Statement Currency Factor");
            end else
                Validate("Statement Amount", IssuedBankStmtLn.Amount);

            Description := IssuedBankStmtLn.Description;
            "Transaction Text" := IssuedBankStmtLn.Description;
            "Related-Party Bank Acc. No." := IssuedBankStmtLn.IBAN;
            if "Related-Party Bank Acc. No." = '' then
                "Related-Party Bank Acc. No." := IssuedBankStmtLn."Account No.";
            "Related-Party Name" := IssuedBankStmtLn.Name;
            "Constant Symbol" := IssuedBankStmtLn."Constant Symbol";
            "Specific Symbol" := IssuedBankStmtLn."Specific Symbol";
            IBAN := IssuedBankStmtLn.IBAN;
            "SWIFT Code" := IssuedBankStmtLn."SWIFT Code";

            if VariableToDescription and (IssuedBankStmtLn."Variable Symbol" <> '') then begin
                Description := IssuedBankStmtLn."Variable Symbol";
                "Transaction Text" := IssuedBankStmtLn."Variable Symbol";
            end;
            if VariableToVariable then
                "Variable Symbol" := IssuedBankStmtLn."Variable Symbol";
            if VariableToExtDocNo then
                "External Document No." := IssuedBankStmtLn."Variable Symbol";

            Insert(true);
        end;
    end;

    local procedure MatchBankPmtApplication(BankAccNo: Code[20]; StatementNo: Code[20])
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
    begin
        if not RunApplAutomatically or HideMessages then
            exit;

        BankAccRecon.Get(BankAccRecon."Statement Type"::"Payment Application", BankAccNo, StatementNo);
        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccRecon);
    end;
}

