page 2340 "BC O365 No. Series Card"
{
    Caption = 'Numbers';
    DataCaptionExpression = GetNoSeriesDescription;
    PageType = StandardDialog;
    SourceTable = "No. Series";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'Specify how you want your invoices to be numbered, such as 0001, INV0001, or INV-0001. This number will then be applied to your next invoice.';
                ShowCaption = false;
                Visible = IsPostedInvoiceNoSeries;
            }
            group(Control5)
            {
                InstructionalText = 'Specify how you want your estimates to be numbered, such as 0001, EST0001, or EST-0001. This number will then be applied to your next estimate.';
                ShowCaption = false;
                Visible = NOT IsPostedInvoiceNoSeries;
            }
            field(NextNo; NextNoSeries)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Next number';
                NotBlank = true;
                ShowCaption = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;

        UpdateLineForNewSeries;
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NextNoSeries: Code[15];
        IsPostedInvoiceNoSeries: Boolean;
        ConfirmNewInvoiceNoSeriesQst: Label 'If you have already sent invoices, please consult your accountant before you change the number sequence.\ \Do you want to continue?';
        InvoiceDocTypeTxt: Label 'Invoice';
        NextNumberTxt: Label 'Next number';
        Confirmed: Boolean;
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = NextNumberText';

    local procedure Initialize()
    var
        LocalNoSeries: Code[20];
    begin
        if SalesReceivablesSetup.Get then;
        if Code = SalesReceivablesSetup."Posted Invoice Nos." then
            IsPostedInvoiceNoSeries := true;
        LocalNoSeries := NoSeriesManagement.ClearStateAndGetNextNo(Code);
        Confirmed := true;
        if StrLen(LocalNoSeries) <= MaxStrLen(NextNoSeries) then
            NextNoSeries := CopyStr(LocalNoSeries, 1, MaxStrLen(NextNoSeries));
    end;

    local procedure UpdateLineForNewSeries()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if NextNoSeries = '' then
            exit;

        if NextNoSeries = NoSeriesManagement.ClearStateAndGetNextNo(Code) then
            exit;

        if IncStr(NextNoSeries) = '' then
            Error(StrSubstNo(UnincrementableStringErr, NextNumberTxt));

        if IsPostedInvoiceNoSeries then
            Confirmed := Confirm(ConfirmNewInvoiceNoSeriesQst);

        if Confirmed then begin
            NoSeriesLine.Reset();
            NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
            NoSeriesLine.SetRange("Series Code", Code);
            NoSeriesLine.SetRange("Starting Date", 0D, WorkDate);
            if NoSeriesLine.FindLast then begin
                NoSeriesLine.Init();
                NoSeriesLine.Validate("Starting No.", NextNoSeries);
                NoSeriesLine.Modify(true);
            end else begin
                NoSeriesLine.Init();
                NoSeriesLine.Validate("Series Code", Code);
                NoSeriesLine.Validate("Line No.", GetNextLineNo(Code));
                NoSeriesLine.Validate("Starting No.", NextNoSeries);
                NoSeriesLine.Insert(true);
            end;
            OnAfterNoSeriesModified;
        end;
    end;

    local procedure GetNoSeriesDescription() NoSeriesDescription: Text
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if SalesReceivablesSetup.Get then;

        if Code = SalesReceivablesSetup."Quote Nos." then
            NoSeriesDescription := Description
        else
            NoSeriesDescription := InvoiceDocTypeTxt;
    end;

    local procedure GetNextLineNo(SeriesCode: Code[20]): Integer
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        if NoSeriesLine.FindLast then;

        exit(NoSeriesLine."Line No." + 10000);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNoSeriesModified()
    begin
    end;
}

