codeunit 7017 "Price List Management"
{
    var
        AllLinesVerifiedMsg: Label 'All price list lines are verified.';
        EmptyPriceSourceErr: Label 'Price source information is missing.';
        VerifyLinesLbl: Label 'Verify lines';
        VerifyLinesMsg: Label 'Not verified lines will not be taken into account during price calculation.';
        VerifyLinesActionMsg: Label 'Not verified lines will not be taken into account during price calculation. Run Verify Lines action to activate modified lines.';
        VerifyLinesNotificationIdTxt: Label '0CDA03EA-8E9F-45BF-B2D7-0F9FADF5F966', Locked = true;

    procedure AddLines(var PriceListHeader: Record "Price List Header")
    var
        PriceLineFilters: Record "Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        PriceLineFilters.Initialize(PriceListHeader, false);
        SuggestPriceLine.SetRecord(PriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(PriceLineFilters);
            AddLines(PriceListHeader, PriceLineFilters);
        end;
    end;

    procedure AddLines(var ToPriceListHeader: Record "Price List Header"; PriceLineFilters: Record "Price Line Filters")
    var
        PriceAsset: Record "Price Asset";
        RecRef: RecordRef;
    begin
        RecRef.Open(PriceLineFilters."Table Id");
        if PriceLineFilters."Asset Filter" <> '' then
            RecRef.SetView(PriceLineFilters."Asset Filter");
        if RecRef.FindSet() then begin
            PriceAsset."Price Type" := ToPriceListHeader."Price Type";
            PriceAsset.Validate("Asset Type", PriceLineFilters."Asset Type");
            repeat
                PriceAsset.Validate("Asset ID", RecRef.Field(RecRef.SystemIdNo()).Value());
                if PriceAsset."Asset No." <> '' then
                    AddLine(ToPriceListHeader, PriceAsset, PriceLineFilters);
            until RecRef.Next() = 0;
        end;
        RecRef.Close();
    end;

    local procedure AddLine(var ToPriceListHeader: Record "Price List Header"; PriceAsset: Record "Price Asset"; PriceLineFilters: Record "Price Line Filters")
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine."Price List Code" := ToPriceListHeader.Code;
        PriceListLine."Line No." := 0; // autoincrement
        PriceListLine.CopyFrom(ToPriceListHeader);
        PriceListLine."Amount Type" := "Price Amount Type"::Price;
        PriceListLine.CopyFrom(PriceAsset);
        PriceListLine.Validate("Minimum Quantity", PriceLineFilters."Minimum Quantity");
        AdjustAmount(PriceAsset."Unit Price", PriceLineFilters);
        case ToPriceListHeader."Price Type" of
            "Price Type"::Sale:
                PriceListLine.Validate("Unit Price", PriceAsset."Unit Price");
            "Price Type"::Purchase:
                begin
                    PriceListLine.Validate("Direct Unit Cost", PriceAsset."Unit Price");
                    AdjustAmount(PriceAsset."Unit Price 2", PriceLineFilters);
                    PriceListLine.Validate("Unit Cost", PriceAsset."Unit Price 2");
                end;
        end;
        PriceListLine.Insert(true);
    end;

    local procedure AdjustAmount(var Price: Decimal; PriceLineFilters: Record "Price Line Filters")
    var
        NewPrice: Decimal;
    begin
        if Price = 0 then
            exit;

        NewPrice := ConvertCurrency(Price, PriceLineFilters);
        NewPrice := NewPrice * PriceLineFilters."Adjustment Factor";

        if not ApplyRoundingMethod(PriceLineFilters."Rounding Method Code", NewPrice) then
            NewPrice := Round(NewPrice, PriceLineFilters."Amount Rounding Precision");

        Price := NewPrice;
    end;

    local procedure ConvertCurrency(Price: Decimal; PriceLineFilters: Record "Price Line Filters") NewPrice: Decimal;
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        NewPrice := Price;
        if PriceLineFilters."From Currency Code" <> PriceLineFilters."To Currency Code" then
            if PriceLineFilters."From Currency Code" = '' then
                NewPrice :=
                    Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                            PriceLineFilters."Exchange Rate Date", PriceLineFilters."To Currency Code", Price,
                            CurrExchRate.ExchangeRate(PriceLineFilters."Exchange Rate Date", PriceLineFilters."To Currency Code")),
                        PriceLineFilters."Amount Rounding Precision")
            else
                if PriceLineFilters."To Currency Code" = '' then
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                                PriceLineFilters."Exchange Rate Date", PriceLineFilters."From Currency Code", Price,
                                CurrExchRate.ExchangeRate(PriceLineFilters."Exchange Rate Date", PriceLineFilters."From Currency Code")),
                            PriceLineFilters."Amount Rounding Precision")
                else
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                                PriceLineFilters."Exchange Rate Date",
                                PriceLineFilters."From Currency Code", PriceLineFilters."To Currency Code",
                                Price),
                            PriceLineFilters."Amount Rounding Precision");
    end;

    local procedure ApplyRoundingMethod(RoundingMethodCode: Code[10]; var Price: Decimal) Rounded: Boolean;
    var
        RoundingMethod: Record "Rounding Method";
    begin
        if Price <= 0 then
            exit(false);

        if RoundingMethodCode <> '' then begin
            RoundingMethod.SetRange(Code, RoundingMethodCode);
            RoundingMethod.SetFilter("Minimum Amount", '<=%1', Price);
            if RoundingMethod.FindLast() then begin
                Price := Price + RoundingMethod."Amount Added Before";
                if RoundingMethod.Precision > 0 then
                    Price :=
                      Round(
                        Price,
                        RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                Price := Price + RoundingMethod."Amount Added After";
                Rounded := true;
            end;
        end;
        if Price < 0 then
            Price := 0;
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header")
    var
        PriceLineFilters: Record "Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        PriceLineFilters.Initialize(ToPriceListHeader, true);
        SuggestPriceLine.SetRecord(PriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(PriceLineFilters);
            CopyLines(ToPriceListHeader, PriceLineFilters);
        end;
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header"; PriceLineFilters: Record "Price Line Filters")
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
    begin
        FromPriceListHeader.Get(PriceLineFilters."From Price List Code");
        if PriceLineFilters."Price Line Filter" <> '' then
            FromPriceListLine.SetView(PriceLineFilters."Price Line Filter");
        FromPriceListLine.SetRange("Price List Code", PriceLineFilters."From Price List Code");
        if FromPriceListLine.FindSet() then
            repeat
                CopyLine(PriceLineFilters, FromPriceListLine, ToPriceListHeader);
            until FromPriceListLine.Next() = 0;
    end;

    local procedure CopyLine(PriceLineFilters: Record "Price Line Filters"; FromPriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header")
    var
        ToPriceListLine: Record "Price List Line";
    begin
        ToPriceListLine := FromPriceListLine;
        ToPriceListLine."Price List Code" := PriceLineFilters."To Price List Code";
        ToPriceListLine.CopyFrom(ToPriceListHeader);
        AdjustAmount(ToPriceListLine."Unit Price", PriceLineFilters);
        AdjustAmount(ToPriceListLine."Direct Unit Cost", PriceLineFilters);
        ToPriceListLine."Line No." := 0;
        ToPriceListLine.Insert(true);
    end;

    procedure FindDuplicatePrices(PriceListHeader: Record "Price List Header"; SearchInside: Boolean; var DuplicatePriceLine: Record "Duplicate Price Line") Found: Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        exit(FindDuplicatePrices(PriceListHeader, PriceListLine, SearchInside, DuplicatePriceLine));
    end;

    local procedure FindDuplicatePrices(PriceListHeader: Record "Price List Header"; var PriceListLine: Record "Price List Line"; SearchInside: Boolean; var DuplicatePriceLine: Record "Duplicate Price Line") Found: Boolean;
    var
        DuplicatePriceListLine: Record "Price List Line";
        LineNo: Integer;
    begin
        DuplicatePriceLine.Reset();
        DuplicatePriceLine.DeleteAll();

        if PriceListLine.FindSet() then
            repeat
                if not DuplicatePriceLine.Get(PriceListLine."Price List Code", PriceListLine."Line No.") then
                    if FindDuplicatePrice(PriceListLine, PriceListHeader."Allow Updating Defaults", SearchInside, DuplicatePriceListLine) then
                        if DuplicatePriceLine.Get(DuplicatePriceListLine."Price List Code", DuplicatePriceListLine."Line No.") then
                            DuplicatePriceLine.Add(LineNo, DuplicatePriceLine."Duplicate To Line No.", PriceListLine)
                        else
                            DuplicatePriceLine.Add(LineNo, PriceListLine, DuplicatePriceListLine);
            until PriceListLine.Next() = 0;
        Found := LineNo > 0;
    end;

    local procedure FindDuplicatePrice(PriceListLine: Record "Price List Line"; AsLineDefaults: Boolean; SearchInside: Boolean; var DuplicatePriceListLine: Record "Price List Line"): Boolean;
    begin
        DuplicatePriceListLine.Reset();
        if SearchInside then begin
            DuplicatePriceListLine.SetRange("Price List Code", PriceListLine."Price List Code");
            DuplicatePriceListLine.SetFilter("Line No.", '<>%1', PriceListLine."Line No.");
            if AsLineDefaults then
                SetHeadersFilters(PriceListLine, DuplicatePriceListLine);
        end else begin
            DuplicatePriceListLine.SetFilter("Price List Code", '<>%1', PriceListLine."Price List Code");
            SetHeadersFilters(PriceListLine, DuplicatePriceListLine);
        end;
        SetAssetFilters(PriceListLine, DuplicatePriceListLine);
        OnBeforeFindDuplicatePriceListLine(PriceListLine, DuplicatePriceListLine);
        exit(DuplicatePriceListLine.FindFirst());
    end;

    procedure IsAllowedEditingActivePrice(PriceType: Enum "Price Type"): Boolean;
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case PriceType of
            "Price Type"::Sale:
                begin
                    SalesReceivablesSetup.Get();
                    exit(SalesReceivablesSetup."Allow Editing Active Price");
                end;
            "Price Type"::Purchase:
                begin
                    PurchasesPayablesSetup.Get();
                    exit(PurchasesPayablesSetup."Allow Editing Active Price");
                end;
        end;
    end;

    procedure SendVerifyLinesNotification()
    var
        VerifyLinesNotification: Notification;
    begin
        VerifyLinesNotification.Id := GetVerifyLinesNotificationId();
        VerifyLinesNotification.Message := VerifyLinesActionMsg;
        VerifyLinesNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        VerifyLinesNotification.Send();
    end;

    procedure SendVerifyLinesNotification(PriceListHeader: Record "Price List Header")
    var
        VerifyLinesNotification: Notification;
    begin
        VerifyLinesNotification.Id := GetVerifyLinesNotificationId();
        VerifyLinesNotification.Message := VerifyLinesMsg;
        VerifyLinesNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        VerifyLinesNotification.SetData(PriceListHeader.FieldName(Code), PriceListHeader.Code);
        VerifyLinesNotification.AddAction(VerifyLinesLbl, CODEUNIT::"Price List Management", 'ActivateDraftLines');
        VerifyLinesNotification.Send();
    end;

    local procedure GetVerifyLinesNotificationId() Id: Guid;
    begin
        Evaluate(Id, VerifyLinesNotificationIdTxt);
    end;

    procedure ActivateDraftLines(VerifyLinesNotification: Notification)
    var
        PriceListHeader: Record "Price List Header";
    begin
        if VerifyLinesNotification.HasData(PriceListHeader.FieldName(Code)) then
            if PriceListHeader.Get(VerifyLinesNotification.GetData(PriceListHeader.FieldName(Code))) then
                ActivateDraftLines(PriceListHeader);
    end;

    procedure ActivateDraftLines(PriceListHeader: Record "Price List Header"): Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        if not PriceListHeader.HasDraftLines(PriceListLine) then
            exit;

        VerifyLines(PriceListLine);
        if not ResolveDuplicatePrices(PriceListHeader) then
            exit(false);

        PriceListLine.ModifyAll(Status, "Price Status"::Active);
        Message(AllLinesVerifiedMsg);
        exit(true);
    end;

    procedure ActivateDraftLines(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        if PriceListLine.IsEmpty() then
            exit;
        VerifyLines(PriceListLine);
        ResolveDuplicatePrices(PriceListLine);
    end;

    procedure VerifyLines(var PriceListLine: Record "Price List Line")
    begin
        if PriceListLine.FindSet() then
            repeat
                PriceListLine.VerifySource();
                if PriceListLine."Asset Type" <> PriceListLine."Asset Type"::" " then
                    PriceListLine.TestField("Asset No.");
            until PriceListLine.Next() = 0;
    end;

    procedure ResolveDuplicatePrices(PriceListHeader: Record "Price List Header"): Boolean
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
    begin
        if FindDuplicatePrices(PriceListHeader, true, DuplicatePriceLine) then
            if not ResolveDuplicatePrices(PriceListHeader, DuplicatePriceLine) then
                exit(false);

        if FindDuplicatePrices(PriceListHeader, false, DuplicatePriceLine) then
            if not ResolveDuplicatePrices(PriceListHeader, DuplicatePriceLine) then
                exit(false);
        exit(true);
    end;

    procedure ResolveDuplicatePrices(var PriceListLine: Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
        PriceListLineLocal: Record "Price List Line";
    begin
        if PriceListLine.FindSet() then
            repeat
                If PriceListHeader.Code <> PriceListLine."Price List Code" then begin
                    if not PriceListHeader.Get(PriceListLine."Price List Code") then
                        PriceListHeader.Code := PriceListLine."Price List Code";
                    if ResolveDuplicatePrices(PriceListHeader) then begin
                        PriceListLineLocal.SetRange("Price List Code", PriceListHeader.Code);
                        PriceListLineLocal.SetRange(Status, "Price Status"::Draft);
                        PriceListLineLocal.ModifyAll(Status, "Price Status"::Active);
                    end;
                end;
            until PriceListLine.Next() = 0;
    end;

    procedure SetPriceListsFilters(var PriceListHeader: Record "Price List Header"; PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListHeader.FilterGroup(2);
        if AmountType <> AmountType::Any then
            PriceListHeader.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);
        SetSourceFilters(PriceSourceList, PriceListHeader);
        PriceListHeader.FilterGroup(0);
    end;

    procedure SetPriceListLineFilters(var PriceListLine: Record "Price List Line"; PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListLine.FilterGroup(2);
        PriceListLine.SetRange("Price Type", PriceSourceList.GetPriceType());
        if AmountType = AmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);

        BuildSourceFilters(PriceListLine, PriceSourceList);
        PriceListLine.MarkedOnly(true);
        PriceListLine.FilterGroup(0);
    end;

    procedure SetPriceListLineFilters(var PriceListLine: Record "Price List Line"; PriceSource: Record "Price Source"; PriceAssetList: Codeunit "Price Asset List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListLine.FilterGroup(2);
        PriceListLine.SetRange("Price Type", PriceSource."Price Type");
        if AmountType = AmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);

        if PriceSource."Source Type" <> PriceSource."Source Type"::All then begin
            PriceListLine.SetRange("Source Type", PriceSource."Source Type");
            PriceListLine.SetRange("Source No.", PriceSource."Source No.");
        end;
        BuildAssetFilters(PriceListLine, PriceAssetList);
        PriceListLine.MarkedOnly(true);
        PriceListLine.FilterGroup(0);
    end;

    local procedure BuildAssetFilters(var PriceListLine: Record "Price List Line"; PriceAssetList: Codeunit "Price Asset List")
    var
        PriceAsset: Record "Price Asset";
    begin
        if PriceAssetList.First(PriceAsset, 0) then
            repeat
                PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
                PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
                if PriceAsset."Variant Code" <> '' then
                    PriceListLine.SetRange("Variant Code", PriceAsset."Variant Code")
                else
                    PriceListLine.SetRange("Variant Code");
                if PriceListLine.FindSet() then
                    repeat
                        PriceListLine.Mark(true);
                    until PriceListLine.Next() = 0;
            until not PriceAssetList.Next(PriceAsset);

        PriceListLine.SetRange("Asset Type");
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange("Variant Code");
    end;

    local procedure BuildSourceFilters(var PriceListLine: Record "Price List Line"; PriceSourceList: Codeunit "Price Source List")
    var
        PriceSource: Record "Price Source";
    begin
        if PriceSourceList.First(PriceSource, 0) then
            repeat
                PriceListLine.SetRange("Source Type", PriceSource."Source Type");
                PriceListLine.SetRange("Parent Source No.", PriceSource."Parent Source No.");
                PriceListLine.SetRange("Source No.", PriceSource."Source No.");
                if PriceListLine.FindSet() then
                    repeat
                        PriceListLine.Mark(true);
                    until PriceListLine.Next() = 0;
            until not PriceSourceList.Next(PriceSource);

        PriceListLine.SetRange("Source Type");
        PriceListLine.SetRange("Source No.");
        PriceListLine.SetRange("Parent Source No.");
    end;

    local procedure SetSourceFilters(PriceSourceList: Codeunit "Price Source List"; var PriceListHeader: Record "Price List Header")
    var
        PriceSource: Record "Price Source";
        SourceFilter: array[3] of Text;
    begin
        PriceSourceList.GetList(PriceSource);
        if not PriceSource.FindSet() then
            Error(EmptyPriceSourceErr);

        PriceListHeader.SetRange("Price Type", PriceSource."Price Type");
        PriceListHeader.SetRange("Source Group", PriceSource."Source Group");

        BuildSourceFilters(PriceSource, SourceFilter);
        if SourceFilter[3] <> '' then
            PriceListHeader.SetFilter("Filter Source No.", SourceFilter[3])
        else begin
            PriceListHeader.SetFilter("Source Type", SourceFilter[1]);
            PriceListHeader.SetFilter("Source No.", SourceFilter[2]);
        end;
    end;

    local procedure BuildSourceFilters(var PriceSource: Record "Price Source"; var SourceFilter: array[3] of Text)
    var
        OrSeparator: Text[1];
    begin
        repeat
            if PriceSource."Source Group" = PriceSource."Source Group"::Job then
                SourceFilter[3] += OrSeparator + GetFilterText(PriceSource."Filter Source No.")
            else begin
                SourceFilter[1] += OrSeparator + Format(PriceSource."Source Type");
                SourceFilter[2] += OrSeparator + GetFilterText(PriceSource."Source No.");
            end;
            OrSeparator := '|';
        until PriceSource.Next() = 0;
    end;

    local procedure GetFilterText(SourceNo: Code[20]): Text;
    begin
        if SourceNo = '' then
            exit('''''');
        exit(SourceNo);
    end;

    local procedure SetHeadersFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        DuplicatePriceListLine.SetRange("Price Type", PriceListLine."Price Type");
        DuplicatePriceListLine.SetRange(Status, "Price Status"::Active);
        DuplicatePriceListLine.SetRange("Source Type", PriceListLine."Source Type");
        DuplicatePriceListLine.SetRange("Parent Source No.", PriceListLine."Parent Source No.");
        DuplicatePriceListLine.SetRange("Source No.", PriceListLine."Source No.");
        DuplicatePriceListLine.SetRange("Currency Code", PriceListLine."Currency Code");
        DuplicatePriceListLine.SetRange("Starting Date", PriceListLine."Starting Date");
    end;

    local procedure SetAssetFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        if PriceListLine."Amount Type" in ["Price Amount Type"::Price, "Price Amount Type"::Discount] then
            DuplicatePriceListLine.SetFilter("Amount Type", '%1|%2', PriceListLine."Amount Type", "Price Amount Type"::Any);
        DuplicatePriceListLine.SetRange("Asset Type", PriceListLine."Asset Type");
        DuplicatePriceListLine.SetRange("Asset No.", PriceListLine."Asset No.");
        DuplicatePriceListLine.SetRange("Unit of Measure Code", PriceListLine."Unit of Measure Code");
        DuplicatePriceListLine.SetRange("Minimum Quantity", PriceListLine."Minimum Quantity");
        case PriceListLine."Asset Type" of
            "Price Asset Type"::Item:
                DuplicatePriceListLine.SetRange("Variant Code", PriceListLine."Variant Code");
            "Price Asset Type"::Resource:
                DuplicatePriceListLine.SetRange("Work Type Code", PriceListLine."Work Type Code");
        end;
    end;

    procedure ResolveDuplicatePrices(PriceListHeader: Record "Price List Header"; var DuplicatePriceLine: Record "Duplicate Price Line") Resolved: Boolean;
    var
        PriceListLine: Record "Price List Line";
        DuplicatePriceLines: Page "Duplicate Price Lines";
    begin
        DuplicatePriceLines.Set(PriceListHeader."Price Type", PriceListHeader."Amount Type", DuplicatePriceLine);
        DuplicatePriceLines.LookupMode(true);
        if DuplicatePriceLines.RunModal() = Action::LookupOK then begin
            DuplicatePriceLines.GetLines(DuplicatePriceLine);
            DuplicatePriceLine.SetRange(Remove, true);
            if DuplicatePriceLine.FindSet() then
                repeat
                    if PriceListLine.Get(DuplicatePriceLine."Price List Code", DuplicatePriceLine."Price List Line No.") then
                        PriceListLine.Delete();
                until DuplicatePriceLine.Next() = 0;
            Resolved := true;
            Commit();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Price List Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnAfterCopyToPriceSource(var Rec: Record "Price List Line"; var xRec: Record "Price List Line"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;
        MarkLineAsDraft(Rec, xRec);
    end;

    local procedure MarkLineAsDraft(var Rec: Record "Price List Line"; var xRec: Record "Price List Line")
    begin
        if Rec.Status = Rec.Status::Active then
            if xRec.Find() and (xRec.Status = Rec.Status) then
                if IsAllowedEditingActivePrice(Rec."Price Type") then
                    Rec.Status := Rec.Status::Draft;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDuplicatePriceListLine(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
    end;
}