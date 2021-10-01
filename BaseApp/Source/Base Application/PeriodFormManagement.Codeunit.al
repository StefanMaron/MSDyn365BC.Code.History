#if not CLEAN19
codeunit 359 PeriodFormManagement
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by PeriodPageManagement.Codeunit.al due to enum implementation.';
    ObsoleteTag = '19.0';

    var
        PeriodPageManagement: Codeunit PeriodPageManagement;

    trigger OnRun()
    begin
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure FindDate(SearchString: Text[3]; var Calendar: Record Date; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"): Boolean
    begin
        exit(PeriodPageManagement.FindDate(SearchString, Calendar, "Analysis Period Type".FromInteger(PeriodType)));
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure NextDate(NextStep: Integer; var Calendar: Record Date; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"): Integer
    begin
        exit(PeriodPageManagement.NextDate(NextStep, Calendar, "Analysis Period Type".FromInteger(PeriodType)));
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure CreatePeriodFormat(PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; Date: Date) PeriodFormat: Text[10]
    begin
        PeriodFormat := PeriodPageManagement.CreatePeriodFormat("Analysis Period Type".FromInteger(PeriodType), Date);
        OnAfterCreatePeriodFormat(PeriodType, Date, PeriodFormat);
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure MoveDateByPeriod(Date: Date; PeriodType: Option; MoveByNoOfPeriods: Integer): Date
    var
        DateExpression: DateFormula;
    begin
        Evaluate(DateExpression, '<' + Format(MoveByNoOfPeriods) + PeriodPageManagement.GetPeriodTypeSymbol(PeriodType) + '>');
        exit(CalcDate(DateExpression, Date));
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure MoveDateByPeriodToEndOfPeriod(Date: Date; PeriodType: Option; MoveByNoOfPeriods: Integer): Date
    var
        DateExpression: DateFormula;
    begin
        Evaluate(DateExpression, '<' + Format(MoveByNoOfPeriods + 1) + PeriodPageManagement.GetPeriodTypeSymbol(PeriodType) + '-1D>');
        exit(CalcDate(DateExpression, Date));
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure GetPeriodTypeSymbol(PeriodType: Option): Text[1]
    begin
        exit(PeriodPageManagement.GetPeriodTypeSymbol(PeriodType));
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure EndOfPeriod(): Date
    begin
        exit(PeriodPageManagement.EndOfPeriod());
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure GetFullPeriodDateFilter(PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DateFilter: Text): Text
    begin
        exit(PeriodPageManagement.GetFullPeriodDateFilter("Analysis Period Type".FromInteger(PeriodType), DateFilter));
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure FindPeriod(var Item: Record Item; SearchText: Text[3]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; AmountType: Enum "Analysis Amount Type")
    begin
        PeriodPageManagement.FindPeriod(Item, SearchText, "Analysis Period Type".FromInteger(PeriodType), AmountType);
    end;

    [Obsolete('Replaced by same procedure in PeriodPageManagement.Codeunit.al due to enum implementation.', '19.0')]
    procedure FindPeriodOnMatrixPage(var DateFilter: Text; var InternalDateFilter: Text; SearchText: Text[3]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; UpdateDateFilter: Boolean)
    begin
        PeriodPageManagement.FindPeriodOnMatrixPage(DateFilter, InternalDateFilter, SearchText, "Analysis Period Type".FromInteger(PeriodType), UpdateDateFilter);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::PeriodPageManagement, 'OnAfterCreatePeriodFormat', '', false, false)]
    local procedure OnAfterCreatePeriodFormatHandler(PeriodType: Enum "Analysis Period Type"; Date: Date; var PeriodFormat: Text[10]);
    begin
        OnAfterCreatePeriodFormat(PeriodType.AsInteger(), Date, PeriodFormat);
    end;

    [Obsolete('Replaced by OnAfterCreatePeriodFormat of PeriodPageManagement.Codeunit.al.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePeriodFormat(PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; Date: Date; var PeriodFormat: Text[10])
    begin
    end;
}
#endif