report 11788 "Create VAT Period"
{
    Caption = 'Create VAT Period';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VATPeriodStartDate; VATPeriodStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date of the VAT year.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of VAT periods.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the length of the VAT period.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if NoOfPeriods = 0 then begin
                NoOfPeriods := 12;
                Evaluate(PeriodLength, '<1M>');
            end;
            if VATPeriod.Find('+') then
                VATPeriodStartDate := VATPeriod."Starting Date";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        VATPeriod."Starting Date" := VATPeriodStartDate;
        VATPeriod.TestField("Starting Date");

        if VATPeriod.Find('-') then begin
            FirstPeriodStartDate := VATPeriod."Starting Date";
            if VATPeriod.Find('+') then
                LastPeriodStartDate := VATPeriod."Starting Date";
        end else
            if not Confirm(Text002 + Text003) then
                exit;

        for i := 1 to NoOfPeriods + 1 do begin
            if (VATPeriodStartDate <= FirstPeriodStartDate) and (i = NoOfPeriods + 1) then
                exit;

            if FirstPeriodStartDate <> 0D then
                if (VATPeriodStartDate >= FirstPeriodStartDate) and (VATPeriodStartDate < LastPeriodStartDate) then
                    Error(Text004);
            VATPeriod.Init();
            VATPeriod."Starting Date" := VATPeriodStartDate;
            VATPeriod.Validate("Starting Date");
            if (i = 1) or (i = NoOfPeriods + 1) then
                VATPeriod."New VAT Year" := true;
            if not VATPeriod.Find('=') then
                VATPeriod.Insert();
            VATPeriodStartDate := CalcDate(PeriodLength, VATPeriodStartDate);
        end;
    end;

    var
        VATPeriod: Record "VAT Period";
        NoOfPeriods: Integer;
        PeriodLength: DateFormula;
        VATPeriodStartDate: Date;
        FirstPeriodStartDate: Date;
        LastPeriodStartDate: Date;
        FirstPeriodLocked: Boolean;
        i: Integer;
        Text002: Label 'Once you create the new VAT year you cannot change its starting date.\\';
        Text003: Label 'Do you want to create the VAT year?';
        Text004: Label 'It is only possible to create new VAT years before or after the existing ones.';
}

