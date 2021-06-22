codeunit 5944 SignServContractDoc
{
    Permissions = TableData "Filed Service Contract Header" = rimd;
    TableNo = "Service Contract Header";

    trigger OnRun()
    begin
    end;

    var
        ServHeader: Record "Service Header";
        ServMgtSetup: Record "Service Mgt. Setup";
        FromServContractHeader: Record "Service Contract Header";
        FromServContractLine: Record "Service Contract Line";
        ToServContractLine: Record "Service Contract Line";
        FiledServContractHeader: Record "Filed Service Contract Header";
        ContractChangeLog: Record "Contract Change Log";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ServContractMgt: Codeunit ServContractManagement;
        ServLogMgt: Codeunit ServLogManagement;
        Window: Dialog;
        ServHeaderNo: Code[20];
        InvoicingStartingPeriod: Boolean;
        InvoiceNow: Boolean;
        GoOut: Boolean;
        Text001: Label 'You cannot convert the service contract quote %1 to a contract,\because some Service Contract Lines have a missing %2.';
        Text003: Label '%1 must be the first day of the month.';
        Text004: Label 'You cannot sign service contract %1,\because some Service Contract Lines have a missing %2.';
        Text005: Label '%1 is not the last day of the month.\\Confirm that this is the correct date.';
        Text010: Label 'Do you want to sign service contract %1?';
        Text011: Label 'Do you want to convert the contract quote into a contract?';
        Text012: Label 'Signing contract          #1######\';
        Text013: Label 'Processing contract lines #2######\';
        WPostLine: Integer;
        Text015: Label 'Do you want to create an invoice for the period %1 .. %2?';
        AppliedEntry: Integer;
        InvoiceFrom: Date;
        InvoiceTo: Date;
        FirstPrepaidPostingDate: Date;
        LastPrepaidPostingDate: Date;
        PostingDate: Date;
        Text016: Label 'Service Invoice %1 was created.';
        Text018: Label 'It is not possible to add new lines to this service contract with the current working date\because it will cause a gap in the invoice period.';
        HideDialog: Boolean;
        Text019: Label 'You cannot sign service contract with negative annual amount.';
        Text020: Label 'You cannot sign service contract with zero annual amount when invoice period is different from None.';
        Text021: Label 'One or more service items on contract quote %1 does not belong to customer %2.';
        Text022: Label 'The %1 field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?';
        Text023: Label 'You cannot sign a service contract if its %1 is not equal to the %2 value.';
        Text024: Label 'You cannot sign a canceled service contract.';

    procedure SignContractQuote(FromServContractHeader: Record "Service Contract Header")
    var
        ToServContractHeader: Record "Service Contract Header";
        FiledServContractHeader2: Record "Filed Service Contract Header";
        RecordLinkManagement: Codeunit "Record Link Management";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforeSignContractQuote(FromServContractHeader);

        if not HideDialog then
            ClearAll;
        CheckServContractQuote(FromServContractHeader);
        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(Text011, true) then
                exit;
        if not HideDialog then
            if not CheckServContractNextPlannedServiceDate(FromServContractHeader) then
                exit;

        Window.Open(
          Text012 +
          Text013);

        FiledServContractHeader.FileQuotationBeforeSigning(FromServContractHeader);

        Window.Update(1, 1);
        WPostLine := 0;
        InvoicingStartingPeriod := false;
        SetInvoicing(FromServContractHeader);

        FirstPrepaidPostingDate := 0D;
        LastPrepaidPostingDate := 0D;

        ToServContractHeader.TransferFields(FromServContractHeader);

        if InvoiceNow then
            PostingDate := InvoiceFrom;

        ToServContractHeader."Contract Type" := ToServContractHeader."Contract Type"::Contract;
        if InvoiceNow then begin
            ToServContractHeader."Last Invoice Date" := ToServContractHeader."Starting Date";
            ToServContractHeader.Validate("Last Invoice Period End", InvoiceTo);
        end;
        OnBeforeToServContractHeaderInsert(ToServContractHeader, FromServContractHeader);
        ToServContractHeader.Insert();
        OnAfterToServContractHeaderInsert(ToServContractHeader, FromServContractHeader);

        if ServMgtSetup."Register Contract Changes" then
            ContractChangeLog.LogContractChange(
              ToServContractHeader."Contract No.", 0, ToServContractHeader.FieldCaption(Status), 0,
              '', Format(ToServContractHeader.Status), '', 0);

        FiledServContractHeader.Reset();
        FiledServContractHeader.SetCurrentKey("Contract Type Relation", "Contract No. Relation");
        FiledServContractHeader.SetRange("Contract Type Relation", FromServContractHeader."Contract Type");
        FiledServContractHeader.SetRange("Contract No. Relation", FromServContractHeader."Contract No.");
        if FiledServContractHeader.FindSet then
            repeat
                FiledServContractHeader2 := FiledServContractHeader;
                FiledServContractHeader2."Contract Type Relation" := ToServContractHeader."Contract Type";
                FiledServContractHeader2."Contract No. Relation" := ToServContractHeader."Contract No.";
                FiledServContractHeader2.Modify();
            until FiledServContractHeader.Next = 0;

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if FromServContractLine.FindSet then
            repeat
                ToServContractLine := FromServContractLine;
                ToServContractLine."Contract Type" := ToServContractLine."Contract Type"::Contract;
                ToServContractLine."Contract No." := FromServContractLine."Contract No.";
                ToServContractLine."Contract Status" := FromServContractLine."Contract Status"::Signed;
                ToServContractLine.SuspendStatusCheck(true);
                OnBeforeToServContractLineInsert(ToServContractLine, FromServContractLine);
                ToServContractLine.Insert(true);
                OnAfterToServContractLineInsert(ToServContractLine, FromServContractLine);
                Clear(ServLogMgt);
                WPostLine := WPostLine + 1;
                Window.Update(2, WPostLine);
            until FromServContractLine.Next = 0;

        CopyServComments(FromServContractHeader, ToServContractHeader);

        if InvoicingStartingPeriod and
           not ToServContractHeader.Prepaid and
           InvoiceNow
        then begin
            ToServContractHeader.Validate("Last Invoice Date", InvoiceTo);
            OnSignContractQuoteOnBeforeToServContractHeaderModify(ToServContractHeader);
            ToServContractHeader.Modify();
        end;

        ToServContractHeader.Status := ToServContractHeader.Status::Signed;
        ToServContractHeader."Change Status" := ToServContractHeader."Change Status"::Locked;
        ToServContractHeader.Modify();
        RecordLinkManagement.CopyLinks(FromServContractHeader, ToServContractHeader);

        if InvoiceNow then begin
            ServMgtSetup.Get();
            CreateServiceLinesLedgerEntries(ToServContractHeader, false);
        end;

        CopyContractServDiscounts(FromServContractHeader, ToServContractHeader);

        ContractGainLossEntry.AddEntry(
          2, ToServContractHeader."Contract Type", ToServContractHeader."Contract No.", FromServContractHeader."Annual Amount", '');

        ToServContractLine.Reset();
        ToServContractLine.SetRange("Contract Type", ToServContractHeader."Contract Type");
        ToServContractLine.SetRange("Contract No.", ToServContractHeader."Contract No.");
        if ToServContractLine.FindSet then
            repeat
                ToServContractLine."New Line" := false;
                ToServContractLine.Modify();
            until ToServContractLine.Next = 0;

        CopyServHours(ToServContractHeader);
        DeleteServContractHeader(FromServContractHeader);

        Window.Close;

        if not HideDialog then
            if ServHeaderNo <> '' then
                Message(Text016, ServHeaderNo);

        OnAfterSignContractQuote(FromServContractHeader, ToServContractHeader);
    end;

    procedure SignContract(FromServContractHeader: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        ServContractHeader: Record "Service Contract Header";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforeSignContract(FromServContractHeader);

        if not HideDialog then
            ClearAll;

        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text010, FromServContractHeader."Contract No."), true)
            then
                exit;

        ServContractHeader.Get(FromServContractHeader."Contract Type", FromServContractHeader."Contract No.");

        if not CheckServContract(ServContractHeader) then
            exit;

        if ServContractHeader.Status = ServContractHeader.Status::Signed then begin
            LockOpenServContract.LockServContract(ServContractHeader);
            exit;
        end;

        Window.Open(Text012 + Text013);

        FiledServContractHeader.FileQuotationBeforeSigning(ServContractHeader);

        Window.Update(1, 1);
        WPostLine := 0;
        InvoicingStartingPeriod := false;
        SetInvoicing(ServContractHeader);

        if InvoiceNow then
            PostingDate := InvoiceFrom;

        if InvoiceNow then begin
            ServContractHeader."Last Invoice Date" := ServContractHeader."Starting Date";
            ServContractHeader.Validate("Last Invoice Period End", InvoiceTo);
        end;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if ServContractLine.FindSet then
            repeat
                ServContractLine."Contract Status" := ServContractLine."Contract Status"::Signed;
                ServContractLine.Modify();
                Clear(ServLogMgt);
                WPostLine := WPostLine + 1;
                Window.Update(2, WPostLine);
            until ServContractLine.Next = 0;

        if InvoicingStartingPeriod and
           not ServContractHeader.Prepaid and
           InvoiceNow
        then begin
            ServContractHeader.Validate("Last Invoice Date", InvoiceTo);
            ServContractHeader.Modify();
        end;

        if InvoiceNow then begin
            ServMgtSetup.Get();
            CreateServiceLinesLedgerEntries(ServContractHeader, false);
        end;

        ContractGainLossEntry.AddEntry(
          2, ServContractHeader."Contract Type",
          ServContractHeader."Contract No.",
          ServContractHeader."Annual Amount", '');

        ServContractHeader.Status := ServContractHeader.Status::Signed;
        ServContractHeader."Change Status" := ServContractHeader."Change Status"::Locked;

        OnBeforeServContractHeaderModify(ServContractHeader, FromServContractHeader);
        ServContractHeader.Modify();

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        if ServContractLine.FindSet then
            repeat
                ServContractLine."New Line" := false;
                ServContractLine.Modify();
            until ServContractLine.Next = 0;

        if ServMgtSetup."Register Contract Changes" then
            ContractChangeLog.LogContractChange(
              ServContractHeader."Contract No.", 0, ServContractHeader.FieldCaption(Status), 0,
              '', Format(ServContractHeader.Status), '', 0);

        Clear(FromServContractHeader);

        Window.Close;

        if not HideDialog then
            if ServHeaderNo <> '' then
                Message(Text016, ServHeaderNo);
    end;

    procedure AddendumToContract(ServContractHeader: Record "Service Contract Header")
    var
        Currency: Record Currency;
        ServContractLine: Record "Service Contract Line";
        ConfirmManagement: Codeunit "Confirm Management";
        TempDate: Date;
        StartingDate: Date;
        RemainingAmt: Decimal;
        InvoicePrepaid: Boolean;
        NonExpiredContractLineExists: Boolean;
        NoOfMonthsAndMParts: Decimal;
    begin
        OnBeforeAddendumToContract(ServContractHeader);

        if not HideDialog then
            ClearAll;

        FromServContractHeader := ServContractHeader;
        if (FromServContractHeader."Invoice Period" = FromServContractHeader."Invoice Period"::None) or
           (FromServContractHeader."Next Invoice Date" = 0D)
        then
            exit;

        ServContractMgt.CheckContractGroupAccounts(ServContractHeader);

        ServMgtSetup.Get();
        Currency.InitRoundingPrecision;

        ServContractLine.Reset();
        ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        ServContractLine.SetRange("New Line", true);
        StartingDate := WorkDate;
        OnAddendumToContractOnAfterSetStartingDate(FromServContractHeader, StartingDate);
        if ServContractLine.FindSet then
            repeat
                if ServMgtSetup."Contract Rsp. Time Mandatory" then
                    ServContractLine.TestField("Response Time (Hours)");
                ServContractLine."Starting Date" := StartingDate;
                if (ServContractLine."Next Planned Service Date" <> 0D) and
                   (ServContractLine."Next Planned Service Date" < StartingDate)
                then
                    ServContractLine."Next Planned Service Date" := StartingDate;
                ServContractLine.Modify();
            until ServContractLine.Next = 0;

        if not HideDialog then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            ServContractLine.SetRange("New Line", true);
            ServContractLine.SetRange("Next Planned Service Date", 0D);
            if ServContractLine.FindFirst then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(Text022, ServContractLine.FieldCaption("Next Planned Service Date")), true)
                then
                    Error('');
        end;

        Window.Open(Text012 + Text013);

        FiledServContractHeader.FileQuotationBeforeSigning(FromServContractHeader);

        Window.Update(1, 1);
        WPostLine := 0;

        InvoicePrepaid := FromServContractHeader.Prepaid;

        TempDate := FromServContractHeader."Next Invoice Period Start";
        if StartingDate < TempDate then begin
            TempDate := TempDate - 1;
        end else begin
            if StartingDate > CalcDate('<CM>', TempDate) then begin
                Window.Close;
                Error(Text018);
            end;
            TempDate := CalcDate('<CM>', StartingDate);
            InvoicePrepaid := true;
        end;

        if StartingDate >= FromServContractHeader."Next Invoice Period Start" then begin
            GoOut := true;
            InvoicePrepaid := false;
        end;

        if not GoOut then begin
            InvoiceFrom := StartingDate;
            InvoiceTo := TempDate;
            InvoicingStartingPeriod := true;
        end;

        if FromServContractHeader.Prepaid and InvoicePrepaid then begin
            FirstPrepaidPostingDate := ServContractMgt.FindFirstPrepaidTransaction(FromServContractHeader."Contract No.");
            if FirstPrepaidPostingDate <> 0D then begin
                if StartingDate < FromServContractHeader."Next Invoice Date" then
                    LastPrepaidPostingDate := FromServContractHeader."Next Invoice Date" - 1
                else
                    LastPrepaidPostingDate := FromServContractHeader."Next Invoice Period End";
                case true of
                    InvoiceFrom < FirstPrepaidPostingDate:
                        InvoiceTo := FirstPrepaidPostingDate - 1;
                    InvoiceFrom > FirstPrepaidPostingDate:
                        if LastPrepaidPostingDate = CalcDate('<CM>', InvoiceFrom) then
                            InvoicePrepaid := false
                        else begin
                            InvoiceTo := CalcDate('<CM>', InvoiceFrom);
                            FirstPrepaidPostingDate := InvoiceTo + 1;
                            if InvoiceFrom > LastPrepaidPostingDate
                            then
                                LastPrepaidPostingDate := FromServContractHeader."Next Invoice Period End";
                        end;
                end;
            end else
                if InvoiceFrom > FromServContractHeader."Next Invoice Period Start" then begin
                    FirstPrepaidPostingDate := CalcDate('<CM>', InvoiceFrom) + 1;
                    if FirstPrepaidPostingDate < FromServContractHeader."Next Invoice Period End" then
                        LastPrepaidPostingDate := FromServContractHeader."Next Invoice Period End"
                    else
                        InvoicePrepaid := false;
                end else
                    InvoicePrepaid := false;
        end;

        if not GoOut then
            if HideDialog then
                InvoiceNow := true
            else begin
                if InvoicePrepaid and (LastPrepaidPostingDate <> 0D)
                then
                    TempDate := LastPrepaidPostingDate;
                if ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text015, StartingDate, TempDate), true) then
                    InvoiceNow := true
                else
                    InvoicePrepaid := false;
            end;

        if FromServContractHeader.Prepaid and InvoicePrepaid then
            if InvoiceFrom = ServContractMgt.FindFirstPrepaidTransaction(FromServContractHeader."Contract No.")
            then
                InvoiceNow := false;

        if InvoiceNow then begin
            PostingDate := InvoiceFrom;
            ServContractLine.Reset();
            ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            ServContractLine.SetRange("New Line", true);
            if ServContractLine.FindSet then
                repeat
                    if (ServContractLine."Contract Expiration Date" <> 0D) and
                       (ServContractLine."Contract Expiration Date" < InvoiceTo)
                    then
                        NoOfMonthsAndMParts := ServContractMgt.NoOfMonthsAndMPartsInPeriod(
                            InvoiceFrom, ServContractLine."Contract Expiration Date")
                    else
                        if (FromServContractHeader."Expiration Date" <> 0D) and
                           (FromServContractHeader."Expiration Date" < InvoiceTo)
                        then
                            NoOfMonthsAndMParts := ServContractMgt.NoOfMonthsAndMPartsInPeriod(
                                InvoiceFrom, FromServContractHeader."Expiration Date")
                        else
                            NoOfMonthsAndMParts :=
                              ServContractMgt.NoOfMonthsAndMPartsInPeriod(InvoiceFrom, InvoiceTo);
                    RemainingAmt :=
                      RemainingAmt +
                      Round(
                        ServContractLine."Line Amount" / 12 * NoOfMonthsAndMParts, Currency."Amount Rounding Precision");
                until ServContractLine.Next = 0;
        end;

        if InvoiceNow then begin
            OnAddendumToContractOnBeforeCreateServiceLinesLedgerEntries(FromServContractHeader);
            CreateServiceLinesLedgerEntries(FromServContractHeader, true);
        end;

        if InvoicePrepaid and FromServContractHeader.Prepaid then begin
            ServContractMgt.InitCodeUnit;
            if ServHeaderNo = '' then
                ServHeaderNo :=
                  ServContractMgt.CreateServHeader(FromServContractHeader, PostingDate, false);

            RemainingAmt := 0;
            ServContractLine.Reset();
            ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            ServContractLine.SetRange("New Line", true);

            if ServContractLine.FindSet then
                repeat
                    InvoiceFrom := FirstPrepaidPostingDate;
                    InvoiceTo := LastPrepaidPostingDate;
                    if (ServContractLine."Contract Expiration Date" <> 0D) and
                       (ServContractLine."Contract Expiration Date" < InvoiceTo)
                    then
                        InvoiceTo := ServContractLine."Contract Expiration Date";
                    if (FromServContractHeader."Expiration Date" <> 0D) and
                       (FromServContractHeader."Expiration Date" < InvoiceTo)
                    then
                        InvoiceTo := FromServContractHeader."Expiration Date";
                    if ServContractLine."Starting Date" > InvoiceFrom then
                        InvoiceFrom := ServContractLine."Starting Date";
                    NoOfMonthsAndMParts :=
                      ServContractMgt.NoOfMonthsAndMPartsInPeriod(InvoiceFrom, InvoiceTo);
                    RemainingAmt :=
                      RemainingAmt +
                      Round(
                        ServContractLine."Line Amount" / 12 * NoOfMonthsAndMParts, Currency."Amount Rounding Precision");
                until ServContractLine.Next = 0;
            if RemainingAmt <> 0 then begin
                ServHeader.Get(ServHeader."Document Type"::Invoice, ServHeaderNo);
                if FromServContractHeader."Contract Lines on Invoice" then begin
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
                    ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
                    ServContractLine.SetRange("New Line", true);
                    if ServContractLine.FindSet then
                        repeat
                            if FromServContractHeader."Contract Lines on Invoice" then
                                ServContractMgt.CreateDetailedServLine(
                                  ServHeader,
                                  ServContractLine,
                                  FromServContractHeader."Contract Type",
                                  FromServContractHeader."Contract No.");

                            AppliedEntry :=
                              ServContractMgt.CreateServiceLedgerEntry(
                                ServHeader, FromServContractHeader."Contract Type",
                                FromServContractHeader."Contract No.", FirstPrepaidPostingDate,
                                LastPrepaidPostingDate, false, true,
                                ServContractLine."Line No.");

                            ServContractMgt.CreateServLine(
                              ServHeader,
                              FromServContractHeader."Contract Type",
                              FromServContractHeader."Contract No.",
                              FirstPrepaidPostingDate, LastPrepaidPostingDate,
                              AppliedEntry, false);
                        until ServContractLine.Next = 0;
                end else begin
                    ServContractMgt.CreateHeadingServLine(
                      ServHeader,
                      FromServContractHeader."Contract Type",
                      FromServContractHeader."Contract No.");

                    AppliedEntry :=
                      ServContractMgt.CreateServiceLedgerEntry(
                        ServHeader, FromServContractHeader."Contract Type",
                        FromServContractHeader."Contract No.", FirstPrepaidPostingDate,
                        LastPrepaidPostingDate, false, true, 0);

                    ServContractMgt.CreateServLine(
                      ServHeader,
                      FromServContractHeader."Contract Type",
                      FromServContractHeader."Contract No.",
                      FirstPrepaidPostingDate, LastPrepaidPostingDate,
                      AppliedEntry, false);
                end;
            end;
            ServContractMgt.FinishCodeunit;
        end;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if ServContractLine.FindSet then
            repeat
                if (ServContractLine."Contract Expiration Date" <> 0D) and (ServContractHeader."Last Invoice Date" <> 0D) then
                    if ServContractLine."Contract Expiration Date" > ServContractHeader."Last Invoice Date" then
                        NonExpiredContractLineExists := true;
            until ServContractLine.Next = 0;
        if InvoiceNow and (not NonExpiredContractLineExists) then begin
            if not FromServContractHeader.Prepaid then
                FromServContractHeader."Last Invoice Date" := InvoiceTo
            else
                FromServContractHeader."Last Invoice Date" := FromServContractHeader."Next Invoice Date";
            FromServContractHeader.Modify();
        end;

        FromServContractHeader.Get(ServContractHeader."Contract Type", ServContractHeader."Contract No.");
        FromServContractHeader."Change Status" := FromServContractHeader."Change Status"::Locked;
        FromServContractHeader.Modify();

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        ServContractLine.ModifyAll("New Line", false);
        Window.Close;

        if not HideDialog then
            if ServHeaderNo <> '' then
                Message(Text016, ServHeaderNo);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure SetInvoicing(ServContractHeader: Record "Service Contract Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        TempDate: Date;
    begin
        if ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None then
            exit;

        if ServContractHeader.Prepaid then begin
            if ServContractHeader."Starting Date" < ServContractHeader."Next Invoice Date" then begin
                if HideDialog then
                    InvoiceNow := true
                else
                    if ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text015, ServContractHeader."Starting Date", ServContractHeader."Next Invoice Date" - 1), true)
                    then
                        InvoiceNow := true;
                InvoiceFrom := ServContractHeader."Starting Date";
                InvoiceTo := ServContractHeader."Next Invoice Date" - 1;
            end
        end else begin
            GoOut := true;
            TempDate := ServContractHeader."Next Invoice Period Start";
            if ServContractHeader."Starting Date" < TempDate then begin
                TempDate := TempDate - 1;
                GoOut := false;
            end;
            if not GoOut then begin
                if HideDialog then
                    InvoiceNow := true
                else
                    if ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text015, ServContractHeader."Starting Date", TempDate), true)
                    then
                        InvoiceNow := true;
                InvoiceFrom := ServContractHeader."Starting Date";
                InvoiceTo := TempDate;
                InvoicingStartingPeriod := true;
            end;
        end;
    end;

    local procedure CheckServContractQuote(FromServContractHeader: Record "Service Contract Header")
    var
        ServItem: Record "Service Item";
    begin
        OnBeforeCheckServContractQuote(FromServContractHeader);

        FromServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
        FromServContractHeader.TestField("Service Period");
        FromServContractHeader.CalcFields("Calcd. Annual Amount");
        if FromServContractHeader."Calcd. Annual Amount" < 0 then
            Error(Text019);
        FromServContractHeader.TestField("Annual Amount", FromServContractHeader."Calcd. Annual Amount");

        ServContractMgt.CheckContractGroupAccounts(FromServContractHeader);

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromServContractLine.SetRange("Line Amount", 0);
        FromServContractLine.SetFilter("Line Discount %", '<%1', 100);
        if FromServContractLine.FindFirst then
            Error(
              Text001,
              FromServContractHeader."Contract No.",
              FromServContractLine.FieldCaption("Line Amount"));

        FromServContractHeader.TestField("Starting Date");
        CheckServContractNonZeroAmounts(FromServContractHeader);

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromServContractLine.SetFilter("Service Item No.", '<>%1', '');
        if FromServContractLine.FindSet then
            repeat
                ServItem.Get(FromServContractLine."Service Item No.");
                if ServItem."Customer No." <> FromServContractHeader."Customer No." then
                    Error(
                      Text021,
                      FromServContractHeader."Contract No.",
                      FromServContractHeader."Customer No.");
            until FromServContractLine.Next = 0;

        ServMgtSetup.Get();
        if ServMgtSetup."Salesperson Mandatory" then
            FromServContractHeader.TestField("Salesperson Code");
        CheckServContractNextInvoiceDate(FromServContractHeader);

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if FromServContractLine.FindSet then
            repeat
                if ServMgtSetup."Contract Rsp. Time Mandatory" then
                    FromServContractLine.TestField("Response Time (Hours)");
            until FromServContractLine.Next = 0;

        ServContractMgt.CopyCheckSCDimToTempSCDim(FromServContractHeader);

        OnAfterCheckServContractQuote(FromServContractHeader);
    end;

    procedure CheckServContract(var ServContractHeader: Record "Service Contract Header"): Boolean
    var
        ServContractLine: Record "Service Contract Line";
    begin
        if ServContractHeader.Status = ServContractHeader.Status::Signed then
            exit(true);
        if ServContractHeader.Status = ServContractHeader.Status::Canceled then
            Error(Text024);
        ServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
        ServContractHeader.TestField("Service Period");
        ServContractHeader.CalcFields("Calcd. Annual Amount");

        if ServContractHeader."Annual Amount" <> ServContractHeader."Calcd. Annual Amount" then
            Error(Text023, ServContractHeader.FieldCaption("Annual Amount"),
              ServContractHeader.FieldCaption("Calcd. Annual Amount"));

        if ServContractHeader."Annual Amount" < 0 then
            Error(Text019);

        ServContractMgt.CheckContractGroupAccounts(ServContractHeader);

        CheckServContractHasZeroAmounts(ServContractHeader);

        ServContractHeader.TestField("Starting Date");
        CheckServContractNonZeroAmounts(ServContractHeader);

        ServMgtSetup.Get();
        if ServMgtSetup."Salesperson Mandatory" then
            ServContractHeader.TestField("Salesperson Code");

        CheckServContractNextInvoiceDate(ServContractHeader);

        if ServMgtSetup."Contract Rsp. Time Mandatory" then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
            ServContractLine.SetRange("Response Time (Hours)", 0);
            if ServContractLine.FindFirst then
                ServContractLine.FieldError("Response Time (Hours)");
        end;
        ServContractMgt.CopyCheckSCDimToTempSCDim(ServContractHeader);

        if not HideDialog then
            exit(CheckServContractNextPlannedServiceDate(ServContractHeader));

        exit(true);
    end;

    local procedure CheckServContractNextInvoiceDate(ServContractHeader: Record "Service Contract Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ServContractHeader.IsInvoicePeriodInTimeSegment then
            if ServContractHeader.Prepaid then begin
                if CalcDate('<-CM>', ServContractHeader."Next Invoice Date") <> ServContractHeader."Next Invoice Date"
                then
                    Error(Text003, ServContractHeader.FieldCaption("Next Invoice Date"));
            end else begin
                if
                   CalcDate('<CM>', ServContractHeader."Next Invoice Date") <> ServContractHeader."Next Invoice Date"
                then
                    if not HideDialog then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text005, ServContractHeader.FieldCaption("Next Invoice Date")), true)
                        then
                            exit;
            end;
    end;

    local procedure CheckServContractNextPlannedServiceDate(ServContractHeader: Record "Service Contract Header"): Boolean
    var
        ServContractLine: Record "Service Contract Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        ServContractLine.SetRange("Next Planned Service Date", 0D);
        if ServContractLine.FindFirst then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text022, ServContractLine.FieldCaption("Next Planned Service Date")), true)
            then
                exit(false);
        exit(true);
    end;

    local procedure CheckServContractNonZeroAmounts(ServContractHeader: Record "Service Contract Header")
    begin
        if ServContractHeader.IsInvoicePeriodInTimeSegment() then begin
            if ServContractHeader."Annual Amount" = 0 then
                Error(Text020);
            ServContractHeader.TestField("Amount per Period");
        end;
    end;

    local procedure CheckServContractHasZeroAmounts(ServContractHeader: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractHasZeroAmounts(ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        ServContractLine.SetRange("Line Amount", 0);
        ServContractLine.SetFilter("Line Discount %", '<%1', 100);
        if not ServContractLine.IsEmpty then
            Error(
              Text004,
              ServContractHeader."Contract No.",
              ServContractLine.FieldCaption("Line Amount"));
    end;

    local procedure CreateServiceLinesLedgerEntries(var ServContractHeader: Record "Service Contract Header"; NewLine: Boolean)
    var
        ServContractLine: Record "Service Contract Line";
    begin
        ServContractMgt.InitCodeUnit;
        ServHeaderNo :=
          ServContractMgt.CreateServHeader(ServContractHeader, PostingDate, false);

        ServHeader.Get(ServHeader."Document Type"::Invoice, ServHeaderNo);
        if ServContractHeader."Contract Lines on Invoice" then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
            if NewLine then
                ServContractLine.SetRange("New Line", true);
            if ServContractLine.FindSet then
                repeat
                    ServContractMgt.CreateDetailedServLine(
                      ServHeader, ServContractLine,
                      ServContractHeader."Contract Type",
                      ServContractHeader."Contract No.");

                    AppliedEntry :=
                      ServContractMgt.CreateServiceLedgerEntry(
                        ServHeader, ServContractHeader."Contract Type",
                        ServContractHeader."Contract No.", InvoiceFrom,
                        InvoiceTo, not NewLine, NewLine,
                        ServContractLine."Line No.");

                    ServContractMgt.CreateServLine(
                      ServHeader,
                      ServContractHeader."Contract Type",
                      ServContractHeader."Contract No.",
                      InvoiceFrom, InvoiceTo, AppliedEntry, not NewLine);
                until ServContractLine.Next = 0;
        end else begin
            ServContractMgt.CreateHeadingServLine(
              ServHeader,
              ServContractHeader."Contract Type",
              ServContractHeader."Contract No.");

            AppliedEntry :=
              ServContractMgt.CreateServiceLedgerEntry(
                ServHeader, ServContractHeader."Contract Type",
                ServContractHeader."Contract No.", InvoiceFrom,
                InvoiceTo, not NewLine, NewLine, 0);

            ServContractMgt.CreateServLine(
              ServHeader,
              ServContractHeader."Contract Type",
              ServContractHeader."Contract No.",
              InvoiceFrom, InvoiceTo, AppliedEntry, not NewLine);
        end;

        ServContractHeader.Modify();
        ServContractMgt.FinishCodeunit;
    end;

    local procedure CopyServComments(FromServContractHeader: Record "Service Contract Header"; ToServContractHeader: Record "Service Contract Header")
    var
        FromServCommentLine: Record "Service Comment Line";
        ToServCommentLine: Record "Service Comment Line";
    begin
        FromServCommentLine.SetRange("Table Name", FromServCommentLine."Table Name"::"Service Contract");
        FromServCommentLine.SetRange("Table Subtype", FromServContractHeader."Contract Type");
        FromServCommentLine.SetRange("No.", FromServContractHeader."Contract No.");
        if FromServCommentLine.FindSet then
            repeat
                ToServCommentLine."Table Name" := ToServCommentLine."Table Name"::"Service Contract";
                ToServCommentLine."Table Subtype" := ToServContractHeader."Contract Type"::Contract;
                ToServCommentLine."Table Line No." := FromServCommentLine."Table Line No.";
                ToServCommentLine."No." := ToServContractHeader."Contract No.";
                ToServCommentLine."Line No." := FromServCommentLine."Line No.";
                ToServCommentLine.Comment := FromServCommentLine.Comment;
                ToServCommentLine.Date := FromServCommentLine.Date;
                ToServCommentLine.Insert();
            until FromServCommentLine.Next = 0;
    end;

    local procedure CopyServHours(ToServContractHeader: Record "Service Contract Header")
    var
        FromServHour: Record "Service Hour";
        ToServHour: Record "Service Hour";
    begin
        FromServHour.Reset();
        FromServHour.SetRange("Service Contract Type", FromServHour."Service Contract Type"::Quote);
        FromServHour.SetRange("Service Contract No.", ToServContractHeader."Contract No.");
        if FromServHour.FindSet then
            repeat
                ToServHour := FromServHour;
                ToServHour."Service Contract Type" := FromServHour."Service Contract Type"::Contract;
                ToServHour."Service Contract No." := ToServContractHeader."Contract No.";
                ToServHour.Insert();
            until FromServHour.Next = 0;
    end;

    local procedure CopyContractServDiscounts(FromServContractHeader: Record "Service Contract Header"; ToServContractHeader: Record "Service Contract Header")
    var
        FromContractServDisc: Record "Contract/Service Discount";
        ToContractServDisc: Record "Contract/Service Discount";
    begin
        FromContractServDisc.Reset();
        FromContractServDisc.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromContractServDisc.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if FromContractServDisc.FindSet then
            repeat
                ToContractServDisc.Copy(FromContractServDisc);
                ToContractServDisc."Contract Type" := FromContractServDisc."Contract Type"::Contract;
                ToContractServDisc."Contract No." := ToServContractHeader."Contract No.";
                if ToContractServDisc.Insert() then;
            until FromContractServDisc.Next = 0;
    end;

    local procedure DeleteServContractHeader(FromServContractHeader: Record "Service Contract Header")
    var
        FromContractServDisc: Record "Contract/Service Discount";
        FromServContractLine: Record "Service Contract Line";
        FromServCommentLine: Record "Service Comment Line";
        FromServHour: Record "Service Hour";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteServContractHeader(FromServContractHeader, IsHandled);
        if IsHandled then
            exit;

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromServContractLine.DeleteAll();
        FromServContractHeader.Delete();

        FromServCommentLine.Reset();
        FromServCommentLine.SetRange("Table Name", FromServCommentLine."Table Name"::"Service Contract");
        FromServCommentLine.SetRange("Table Subtype", FromServContractHeader."Contract Type");
        FromServCommentLine.SetRange("No.", FromServContractHeader."Contract No.");
        FromServCommentLine.DeleteAll();

        FromContractServDisc.Reset();
        FromContractServDisc.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromContractServDisc.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromContractServDisc.DeleteAll();

        FromServHour.Reset();
        FromServHour.SetRange("Service Contract Type", FromServHour."Service Contract Type"::Quote);
        FromServHour.SetRange("Service Contract No.", FromServContractHeader."Contract No.");
        FromServHour.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnAfterSetStartingDate(FromServContractHeader: Record "Service Contract Header"; var StartingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToServContractHeaderInsert(var ToServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToServContractLineInsert(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddendumToContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractHasZeroAmounts(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractHeaderModify(var ServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToServContractHeaderInsert(var ToServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToServContractLineInsert(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSignContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSignContractQuote(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSignContractQuote(var SourceServiceContractHeader: Record "Service Contract Header"; var DestServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractQuoteOnBeforeToServContractHeaderModify(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnBeforeCreateServiceLinesLedgerEntries(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractQuote(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckServContractQuote(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServContractHeader(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;
}

