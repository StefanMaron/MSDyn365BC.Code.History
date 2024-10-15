codeunit 12148 "No. Series IT"
{
    Access = Internal;

    var
        CantChangeNoSeriesLineTypeErr: Label '%1 must be deleted before changing the %2.', Comment = '%1 = Table caption %2 = No. Series Type';

    procedure ValidateNoSeriesType(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries."No. Series Type" = xRecNoSeries."No. Series Type" then
            exit;

        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        if not NoSeriesLine.IsEmpty() then
            Error(CantChangeNoSeriesLineTypeErr, NoSeriesLine.TableCaption(), NoSeries.FieldCaption("No. Series Type"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", OnBeforeValidateEvent, "Implementation", false, false)]
    local procedure DisableImplementationsWithGapsInNosOnBeforeValidate(var Rec: Record "No. Series Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        Rec.CalcFields("No. Series Type");
        if (Rec."No. Series Type" in [Rec."No. Series Type"::Sales, Rec."No. Series Type"::Purchase]) and NoSeries.MayProduceGaps(Rec) then
            Rec."Implementation" := Enum::"No. Series Implementation"::Normal;
    end;

#if not CLEAN24
#pragma warning disable AL0432
    procedure DrillDown(var NoSeriesRec: Record "No. Series")
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        GeneralLedgerSetup: Record "General Ledger Setup";
        NoSeries: Codeunit "No. Series";
    begin
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Use Legacy No. Series Lines" then begin
            NoSeries.DrillDown(NoSeriesRec);
            exit;
        end;

        case NoSeriesRec."No. Series Type" of
            Enum::"No. Series Type"::Normal:
                NoSeries.DrillDown(NoSeriesRec);
            Enum::"No. Series Type"::Sales:
                begin
                    FindNoSeriesLineSalesToShow(NoSeriesRec, NoSeriesLineSales);
                    if NoSeriesLineSales.Find('-') then;
                    NoSeriesLineSales.SetRange("Starting Date");
                    NoSeriesLineSales.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLineSales);
                end;
            Enum::"No. Series Type"::Purchase:
                begin
                    FindNoSeriesLinePurchToShow(NoSeriesRec, NoSeriesLinePurchase);
                    if NoSeriesLinePurchase.Find('-') then;
                    NoSeriesLinePurchase.SetRange("Starting Date");
                    NoSeriesLinePurchase.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLinePurchase);
                end;
        end;
    end;

    local procedure FindNoSeriesLineSalesToShow(var NoSeries: Record "No. Series"; var NoSeriesLineSales: Record "No. Series Line Sales")
    begin
        SetNoSeriesLineSalesFilter(NoSeriesLineSales, NoSeries.Code, 0D);

        if NoSeriesLineSales.FindLast() then
            exit;

        NoSeriesLineSales.Reset();
        NoSeriesLineSales.SetRange("Series Code", NoSeries.Code);
    end;

    local procedure FindNoSeriesLinePurchToShow(var NoSeries: Record "No. Series"; var NoSeriesLinePurchase: Record "No. Series Line Purchase")
    begin
        SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, NoSeries.Code, 0D);

        if NoSeriesLinePurchase.FindLast() then
            exit;

        NoSeriesLinePurchase.Reset();
        NoSeriesLinePurchase.SetRange("Series Code", NoSeries.Code);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, OnObsoleteSetNoSeriesLineSalesFilter, '', false, false)]
    local procedure SetNoSeriesLineSalesFilter(var NoSeriesLineSales: Record "No. Series Line Sales"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        if StartDate = 0D then
            StartDate := WorkDate();
        NoSeriesLineSales.Reset();
        NoSeriesLineSales.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLineSales.SetRange("Series Code", NoSeriesCode);
        NoSeriesLineSales.SetRange("Starting Date", 0D, StartDate);
        if NoSeriesLineSales.Find('+') then begin
            NoSeriesLineSales.SetRange("Starting Date", NoSeriesLineSales."Starting Date");
            NoSeriesLineSales.SetRange(Open, true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, OnObsoleteSetNoSeriesLinePurchaseFilter, '', false, false)]
    local procedure SetNoSeriesLinePurchaseFilter(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        if StartDate = 0D then
            StartDate := WorkDate();
        NoSeriesLinePurchase.Reset();
        NoSeriesLinePurchase.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLinePurchase.SetRange("Series Code", NoSeriesCode);
        NoSeriesLinePurchase.SetRange("Starting Date", 0D, StartDate);
        if NoSeriesLinePurchase.Find('+') then begin
            NoSeriesLinePurchase.SetRange("Starting Date", NoSeriesLinePurchase."Starting Date");
            NoSeriesLinePurchase.SetRange(Open, true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::NoSeriesManagement, OnBeforeUpdateLine, '', false, false)]
    local procedure UpdateOnNoSeriesUpdateLine(var NoSeries: Record "No. Series"; var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var Implementation: Enum "No. Series Implementation"; var IsHandled: Boolean)
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Use Legacy No. Series Lines" then
            exit;

        case NoSeries."No. Series Type" of
            Enum::"No. Series Type"::Sales:
                begin
                    FindNoSeriesLineSalesToShow(NoSeries, NoSeriesLineSales);
                    if not NoSeriesLineSales.Find('-') then
                        NoSeriesLineSales.Init();
                    StartDate := NoSeriesLineSales."Starting Date";
                    StartNo := NoSeriesLineSales."Starting No.";
                    EndNo := NoSeriesLineSales."Ending No.";
                    LastNoUsed := NoSeriesLineSales."Last No. Used";
                    WarningNo := NoSeriesLineSales."Warning No.";
                    IncrementByNo := NoSeriesLineSales."Increment-by No.";
                    LastDateUsed := NoSeriesLineSales."Last Date Used";
                    Implementation := Enum::"No. Series Implementation"::Normal;
                    IsHandled := true;
                end;
            Enum::"No. Series Type"::Purchase:
                begin
                    FindNoSeriesLinePurchToShow(NoSeries, NoSeriesLinePurchase);
                    if not NoSeriesLinePurchase.Find('-') then
                        NoSeriesLinePurchase.Init();
                    StartDate := NoSeriesLinePurchase."Starting Date";
                    StartNo := NoSeriesLinePurchase."Starting No.";
                    EndNo := NoSeriesLinePurchase."Ending No.";
                    LastNoUsed := NoSeriesLinePurchase."Last No. Used";
                    WarningNo := NoSeriesLinePurchase."Warning No.";
                    IncrementByNo := NoSeriesLinePurchase."Increment-by No.";
                    LastDateUsed := NoSeriesLinePurchase."Last Date Used";
                    Implementation := Enum::"No. Series Implementation"::Normal;
                    IsHandled := true;
                end;
        end;
    end;

    procedure ShowNoSeriesLines(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        case NoSeries."No. Series Type" of
            Enum::"No. Series Type"::Normal:
                begin
                    NoSeriesLine.SetRange("Series Code", NoSeries.Code);
                    PAGE.RunModal(0, NoSeriesLine);
                end;
            Enum::"No. Series Type"::Sales:
                begin
                    NoSeriesLineSales.SetRange("Series Code", NoSeries.Code);
                    PAGE.RunModal(0, NoSeriesLineSales);
                end;
            Enum::"No. Series Type"::Purchase:
                begin
                    NoSeriesLinePurchase.SetRange("Series Code", NoSeries.Code);
                    PAGE.RunModal(0, NoSeriesLinePurchase);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", OnBeforeValidateEvent, "Allow Gaps in Nos.", false, false)]
    local procedure DisableAllowGapsInNosOnBeforeValidate(var Rec: Record "No. Series Line")
    begin
        Rec.CalcFields("No. Series Type");
        if (Rec."No. Series Type" in [Rec."No. Series Type"::Sales, Rec."No. Series Type"::Purchase]) and Rec."Allow Gaps in Nos." then
            Rec."Allow Gaps in Nos." := false;
    end;
#pragma warning restore AL0432
#endif
}