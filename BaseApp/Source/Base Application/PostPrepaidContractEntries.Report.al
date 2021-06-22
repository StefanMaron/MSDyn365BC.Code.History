report 6032 "Post Prepaid Contract Entries"
{
    ApplicationArea = Service;
    Caption = 'Post Prepaid Service Contract Entries';
    Permissions = TableData "Service Ledger Entry" = rm;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Ledger Entry"; "Service Ledger Entry")
        {
            DataItemTableView = SORTING("Service Contract No.") WHERE(Type = CONST("Service Contract"), "Moved from Prepaid Acc." = CONST(false), Open = CONST(false));
            RequestFilterFields = "Service Contract No.";

            trigger OnAfterGetRecord()
            begin
                Counter := Counter + 1;
                Window.Update(1, "Service Contract No.");
                Window.Update(2, Round(Counter / NoOfContracts * 10000, 1));

                ServLedgEntry.Get("Entry No.");
                ServLedgEntry."Moved from Prepaid Acc." := true;
                ServLedgEntry.Modify();

                if not (LastContract in ['', "Service Contract No."]) then begin
                    TempServLedgEntry.Reset();
                    TempServLedgEntry.SetRange("Service Contract No.", LastContract);
                    TempServLedgEntry.CalcSums("Amount (LCY)");
                    if TempServLedgEntry."Amount (LCY)" <> 0 then
                        PostGenJnlLine
                    else
                        TempServLedgEntry.DeleteAll();
                    TempServLedgEntry.SetRange("Service Contract No.", "Service Contract No.");
                end;

                LastContract := "Service Contract No.";

                if SalesSetup."Discount Posting" in
                   [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
                then
                    AmtInclDisc := Round(("Amount (LCY)" / (1 - ("Discount %" / 100))))
                else
                    AmtInclDisc := "Amount (LCY)";

                TempServLedgEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                if TempServLedgEntry.FindFirst then begin
                    TempServLedgEntry."Amount (LCY)" += AmtInclDisc;
                    TempServLedgEntry.Modify();
                end else begin
                    TempServLedgEntry := "Service Ledger Entry";
                    TempServLedgEntry."Amount (LCY)" := AmtInclDisc;
                    TempServLedgEntry.Insert();
                end;
            end;

            trigger OnPostDataItem()
            var
                UpdateAnalysisView: Codeunit "Update Analysis View";
            begin
                if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then begin
                    TempServLedgEntry.SetRange("Dimension Set ID");
                    TempServLedgEntry.CalcSums("Amount (LCY)");
                    if TempServLedgEntry."Amount (LCY)" <> 0 then begin
                        PostGenJnlLine;
                        UpdateAnalysisView.UpdateAll(0, true);
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if PostPrepaidContracts = PostPrepaidContracts::"Print Only" then begin
                    Clear(PrepaidContractEntriesTest);
                    PrepaidContractEntriesTest.InitVariables(UntilDate, PostingDate);
                    PrepaidContractEntriesTest.SetTableView("Service Ledger Entry");
                    PrepaidContractEntriesTest.RunModal;
                    CurrReport.Break();
                end;

                if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then begin
                    ServContractHdr.SetFilter("Contract No.", GetFilter("Service Contract No."));
                    if ServContractHdr.Find('-') then begin
                        repeat
                            ServContractHdr.CalcFields("No. of Unposted Credit Memos");
                            if ServContractHdr."No. of Unposted Credit Memos" <> 0 then
                                Error(Text005, Text007, Text008, ServContractHdr."Contract No.", Text006);
                        until ServContractHdr.Next = 0;
                    end;
                end;

                LastContract := '';
                if UntilDate = 0D then
                    Error(Text000);
                if PostingDate = 0D then
                    Error(Text001);

                SetRange("Posting Date", 0D, UntilDate);

                NoOfContracts := Count;

                Window.Open(
                  Text002 +
                  Text003 +
                  '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

                ServMgtSetup.Get();
                ServMgtSetup.TestField("Prepaid Posting Document Nos.");
                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Service Management");
                SalesSetup.Get();
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
                    field(UntilDate; UntilDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Post until Date';
                        MultiLine = true;
                        ToolTip = 'Specifies the date up to which you want to post prepaid entries. The batch job includes service ledger entries with posting dates on or before this date.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        MultiLine = true;
                        ToolTip = 'Specifies the date that you want to use as the posting date on the service ledger entries.';
                    }
                    field(PostPrepaidContracts; PostPrepaidContracts)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Post Prepaid Transactions,Print Only';
                        ToolTip = 'Specifies the desired action relating to prepaid contract entries.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        PostingDate := WorkDate;
        Clear(GenJnlPostLine);
    end;

    trigger OnPostReport()
    begin
        if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then
            Window.Close;
    end;

    var
        Text000: Label 'You must fill in the Post Until Date field.';
        Text001: Label 'You must fill in the Posting Date field.';
        Text002: Label 'Posting prepaid contract entries...\';
        Text003: Label 'Service Contract: #1###############\\';
        Text004: Label 'Service Contract';
        GenJnlLine: Record "Gen. Journal Line";
        ServLedgEntry: Record "Service Ledger Entry";
        TempServLedgEntry: Record "Service Ledger Entry" temporary;
        ServContractAccGr: Record "Service Contract Account Group";
        ServMgtSetup: Record "Service Mgt. Setup";
        SourceCodeSetup: Record "Source Code Setup";
        ServContractHdr: Record "Service Contract Header";
        SalesSetup: Record "Sales & Receivables Setup";
        PrepaidContractEntriesTest: Report "Prepaid Contr. Entries - Test";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostPrepaidContracts: Option "Post Prepaid Transactions","Print Only";
        DocNo: Code[20];
        UntilDate: Date;
        PostingDate: Date;
        NoOfContracts: Integer;
        Counter: Integer;
        AmtInclDisc: Decimal;
        LastContract: Code[20];
        Text005: Label 'You cannot post %1 because %2 %3 has at least one %4 linked to it.';
        Text006: Label 'Unposted Credit Memo';
        Text007: Label 'Prepaid Contract Entries';
        Text008: Label 'Service Contract';

    local procedure PostGenJnlLine()
    var
        IsPrepaidAccountPostingHandled: Boolean;
        IsNonPrepaidAccountPostingHandled: Boolean;
    begin
        TempServLedgEntry.Reset();
        if not TempServLedgEntry.FindSet then
            exit;

        DocNo := NoSeriesMgt.GetNextNo(ServMgtSetup."Prepaid Posting Document Nos.", WorkDate, true);

        repeat
            IsNonPrepaidAccountPostingHandled := false;
            OnBeforePostNonPrepaidAccount(GenJnlLine, TempServLedgEntry, IsNonPrepaidAccountPostingHandled);
            if not IsNonPrepaidAccountPostingHandled then begin
                GenJnlLine.Reset();
                GenJnlLine.Init();
                GenJnlLine."Document No." := DocNo;
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                ServContractAccGr.Get(TempServLedgEntry."Serv. Contract Acc. Gr. Code");
                ServContractAccGr.TestField("Non-Prepaid Contract Acc.");
                GenJnlLine.Validate("Account No.", ServContractAccGr."Non-Prepaid Contract Acc.");
                GenJnlLine."Posting Date" := PostingDate;
                GenJnlLine.Description := Text004;
                GenJnlLine."External Document No." := TempServLedgEntry."Service Contract No.";
                GenJnlLine.Validate(Amount, TempServLedgEntry."Amount (LCY)");
                GenJnlLine."Shortcut Dimension 1 Code" := TempServLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempServLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TempServLedgEntry."Dimension Set ID";
                GenJnlLine."Source Code" := SourceCodeSetup."Service Management";
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
                GenJnlLine."Gen. Bus. Posting Group" := '';
                GenJnlLine."Gen. Prod. Posting Group" := '';
                GenJnlLine."VAT Bus. Posting Group" := '';
                GenJnlLine."VAT Prod. Posting Group" := '';
                GenJnlPostLine.Run(GenJnlLine);
            end;

            IsPrepaidAccountPostingHandled := false;
            OnBeforePostPrepaidAccount(GenJnlLine, TempServLedgEntry, IsPrepaidAccountPostingHandled);
            if not IsPrepaidAccountPostingHandled then begin
                ServContractAccGr.Get(TempServLedgEntry."Serv. Contract Acc. Gr. Code");
                ServContractAccGr.TestField("Prepaid Contract Acc.");
                GenJnlLine.Validate("Account No.", ServContractAccGr."Prepaid Contract Acc.");
                GenJnlLine.Validate(Amount, -TempServLedgEntry."Amount (LCY)");
                GenJnlLine."Shortcut Dimension 1 Code" := TempServLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempServLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TempServLedgEntry."Dimension Set ID";
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
                GenJnlLine."Gen. Bus. Posting Group" := '';
                GenJnlLine."Gen. Prod. Posting Group" := '';
                GenJnlLine."VAT Bus. Posting Group" := '';
                GenJnlLine."VAT Prod. Posting Group" := '';
                GenJnlPostLine.Run(GenJnlLine);
            end;
        until TempServLedgEntry.Next = 0;

        TempServLedgEntry.Reset();
        TempServLedgEntry.DeleteAll();
    end;

    procedure InitializeRequest(UntilDateFrom: Date; PostingDateFrom: Date; PostPrepaidContractsFrom: Option "Post Prepaid Transactions","Print Only")
    begin
        UntilDate := UntilDateFrom;
        PostingDate := PostingDateFrom;
        PostPrepaidContracts := PostPrepaidContractsFrom;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostNonPrepaidAccount(var GenJnlLine: Record "Gen. Journal Line"; var TempServLedgEntry: Record "Service Ledger Entry"; var IsNonPrepaidAccountPostingHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepaidAccount(var GenJnlLine: Record "Gen. Journal Line"; var TempServLedgEntry: Record "Service Ledger Entry"; var IsPrepaidAccountPostingHandled: Boolean)
    begin
    end;
}

