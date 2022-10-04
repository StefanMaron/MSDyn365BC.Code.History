codeunit 481 "Check Dimensions"
{

    trigger OnRun()
    begin
    end;

    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        DimMgt: Codeunit DimensionManagement;

        DimensionIsBlockedErr: Label 'The combination of dimensions used in %1 %2 is blocked', Comment = '%1 = Document Type, %2 = Document No, %3 = Error text';
        LineDimensionBlockedErr: Label 'The combination of dimensions used in %1 %2, line no. %3 is blocked', Comment = '%1 = Document Type, %2 = Document No, %3 = LineNo., %4 = Error text';
        InvalidDimensionsErr: Label 'The dimensions used in %1 %2 are invalid', Comment = '%1 = Document Type, %2 = Document No, %3 = Error text';
        LineInvalidDimensionsErr: Label 'The dimensions used in %1 %2, line no. %3 are invalid', Comment = '%1 = Document Type, %2 = Document No, %3 = LineNo., %4 = Error text';

    procedure CheckPurchDim(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        TempPurchLineLocal: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDim(PurchHeader, TempPurchLine, IsHandled);
        if IsHandled then
            exit;

        DimMgt.SetCollectErrorsMode();
        CheckPurchDimCombHeader(PurchHeader);
        CheckPurchDimValuePostingHeader(PurchHeader);

        TempPurchLineLocal.Copy(TempPurchLine, true);
        CheckPurchDimLines(PurchHeader, TempPurchLineLocal);
    end;

    local procedure CheckPurchDimCombHeader(PurchHeader: Record "Purchase Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        with PurchHeader do begin
            ContextErrorMessage := StrSubstNo(DimensionIsBlockedErr, "Document Type", "No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    local procedure CheckPurchDimCombLine(PurchLine: Record "Purchase Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        with PurchLine do begin
            ContextErrorMessage := StrSubstNo(LineDimensionBlockedErr, "Document Type", "Document No.", "Line No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    local procedure CheckPurchDimLines(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    begin
        with TempPurchLine do begin
            Reset();
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet() then
                repeat
                    if (PurchHeader.Receive and ("Qty. to Receive" <> 0)) or
                       (PurchHeader.Invoice and ("Qty. to Invoice" <> 0)) or
                       (PurchHeader.Ship and ("Return Qty. to Ship" <> 0))
                    then begin
                        CheckPurchDimCombLine(TempPurchLine);
                        CheckPurchDimValuePostingLine(TempPurchLine);
                        OnCheckPurchDimLinesOnAfterCheckPurchDimValuePostingLine(TempPurchLine);
                    end
                until Next() = 0;
        end;
    end;

    local procedure CheckPurchDimValuePostingHeader(PurchHeader: Record "Purchase Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        with PurchHeader do begin
            TableIDArr[1] := DATABASE::Vendor;
            NumberArr[1] := "Pay-to Vendor No.";
            TableIDArr[2] := DATABASE::"Salesperson/Purchaser";
            NumberArr[2] := "Purchaser Code";
            TableIDArr[3] := DATABASE::Campaign;
            NumberArr[3] := "Campaign No.";
            TableIDArr[4] := DATABASE::"Responsibility Center";
            NumberArr[4] := "Responsibility Center";
            TableIDArr[5] := Database::Location;
            NumberArr[5] := "Location Code";
            OnCheckDimValuePostingOnAfterCreateDimTableIDs(PurchHeader, TableIDArr, NumberArr);

            DimMgt.SetSourceCode(DATABASE::"Purchase Header", PurchHeader);
            ContextErrorMessage := StrSubstNo(InvalidDimensionsErr, "Document Type", "No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, "Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    local procedure CheckPurchDimValuePostingLine(PurchLine: Record "Purchase Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        with PurchLine do begin
            TableIDArr[1] := DimMgt.PurchLineTypeToTableID(Type);
            NumberArr[1] := "No.";
            TableIDArr[2] := DATABASE::Job;
            NumberArr[2] := "Job No.";
            TableIDArr[3] := DATABASE::"Work Center";
            NumberArr[3] := "Work Center No.";
            TableIDArr[4] := Database::Location;
            NumberArr[4] := "Location Code";
            OnCheckDimValuePostingOnAfterCreateDimTableIDs(PurchLine, TableIDArr, NumberArr);

            DimMgt.SetSourceCode(DATABASE::"Purchase Line", PurchLine);
            ContextErrorMessage := StrSubstNo(LineInvalidDimensionsErr, "Document Type", "Document No.", "Line No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, "Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    procedure CheckPurchPrepmtDim(PurchHeader: Record "Purchase Header")
    begin
        DimMgt.SetCollectErrorsMode();
        CheckPurchDimCombHeader(PurchHeader);
        CheckPurchDimValuePostingHeader(PurchHeader);

        CheckPurchPrepmtDimLines(PurchHeader);
    end;

    local procedure CheckPurchPrepmtDimLines(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            Reset();
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepayment %", '<>0');
            if FindSet() then
                repeat
                    CheckPurchDimCombLine(PurchLine);
                    CheckPurchDimValuePostingLine(PurchLine);
                until Next() = 0;
        end;
    end;

    procedure CheckSalesDim(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    var
        TempSalesLineLocal: Record "Sales Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDim(SalesHeader, TempSalesLine, IsHandled);
        if IsHandled then
            exit;

        DimMgt.SetCollectErrorsMode();
        CheckSalesDimCombHeader(SalesHeader);
        CheckSalesDimValuePostingHeader(SalesHeader);

        TempSalesLineLocal.Copy(TempSalesLine, true);
        CheckSalesDimLines(SalesHeader, TempSalesLineLocal);
    end;

    local procedure CheckSalesDimCombHeader(SalesHeader: Record "Sales Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        with SalesHeader do begin
            ContextErrorMessage := StrSubstNo(DimensionIsBlockedErr, "Document Type", "No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    local procedure CheckSalesDimCombLine(SalesLine: Record "Sales Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
    begin
        with SalesLine do begin
            ContextErrorMessage := StrSubstNo(LineDimensionBlockedErr, "Document Type", "Document No.", "Line No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    local procedure CheckSalesDimLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    var
        ShouldCheckDimensions: Boolean;
    begin
        with TempSalesLine do begin
            Reset();
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet() then
                repeat
                    ShouldCheckDimensions := (SalesHeader.Invoice and ("Qty. to Invoice" <> 0)) or
                                             (SalesHeader.Ship and ("Qty. to Ship" <> 0)) or
                                             (SalesHeader.Receive and ("Return Qty. to Receive" <> 0));
                    OnCheckSalesDimLinesOnAfterCalcShouldCheckDimensions(SalesHeader, TempSalesLine, ShouldCheckDimensions);
                    if ShouldCheckDimensions then begin
                        CheckSalesDimCombLine(TempSalesLine);
                        CheckSalesDimValuePostingLine(TempSalesLine);
                    end
                until Next() = 0;
        end;
    end;

    local procedure CheckSalesDimValuePostingHeader(SalesHeader: Record "Sales Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        with SalesHeader do begin
            TableIDArr[1] := DATABASE::Customer;
            NumberArr[1] := "Bill-to Customer No.";
            TableIDArr[2] := DATABASE::"Salesperson/Purchaser";
            NumberArr[2] := "Salesperson Code";
            TableIDArr[3] := DATABASE::Campaign;
            NumberArr[3] := "Campaign No.";
            TableIDArr[4] := DATABASE::"Responsibility Center";
            NumberArr[4] := "Responsibility Center";
            TableIDArr[5] := Database::Location;
            NumberArr[5] := "Location Code";
            OnCheckDimValuePostingOnAfterCreateDimTableIDs(SalesHeader, TableIDArr, NumberArr);

            DimMgt.SetSourceCode(DATABASE::"Sales Header", SalesHeader);
            ContextErrorMessage := StrSubstNo(InvalidDimensionsErr, "Document Type", "No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, "Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    local procedure CheckSalesDimValuePostingLine(SalesLine: Record "Sales Line")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ContextErrorMessage: Text[250];
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        with SalesLine do begin
            TableIDArr[1] := DimMgt.SalesLineTypeToTableID(Type);
            NumberArr[1] := "No.";
            TableIDArr[2] := DATABASE::Job;
            NumberArr[2] := "Job No.";
            TableIDArr[3] := Database::Location;
            NumberArr[3] := "Location Code";
            DimMgt.SetSourceCode(DATABASE::"Sales Line", SalesLine);
            OnCheckDimValuePostingOnAfterCreateDimTableIDs(SalesLine, TableIDArr, NumberArr);

            ContextErrorMessage := StrSubstNo(LineInvalidDimensionsErr, "Document Type", "Document No.", "Line No.");
            ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, ContextErrorMessage);
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, "Dimension Set ID") then
                ErrorMessageMgt.ThrowError(ContextErrorMessage, DimMgt.GetDimErr());
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
    end;

    procedure CheckSalesPrepmtDim(SalesHeader: Record "Sales Header")
    begin
        DimMgt.SetCollectErrorsMode();
        CheckSalesDimCombHeader(SalesHeader);
        CheckSalesDimValuePostingHeader(SalesHeader);

        CheckSalesPrepmtDimLines(SalesHeader);
    end;

    local procedure CheckSalesPrepmtDimLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            Reset();
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter("Prepayment %", '<>0');
            if FindSet() then
                repeat
                    CheckSalesDimCombLine(SalesLine);
                    CheckSalesDimValuePostingLine(SalesLine);
                until Next() = 0;
        end;
    end;

    local procedure ShowDimensionsSetup(RecID: RecordID): Boolean
    var
        Dimension: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        DimensionCombinations: Page "Dimension Combinations";
        MyDimValueCombinations: Page "MyDim Value Combinations";
        RecRef: RecordRef;
    begin
        case RecID.TableNo of
            DATABASE::Dimension:
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(Dimension);
                    PAGE.Run(PAGE::Dimensions, Dimension);
                end;
            DATABASE::"Dimension Combination":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(DimensionCombination);
                    DimensionCombinations.SetSelectedRecord(DimensionCombination);
                    DimensionCombinations.Run();
                end;
            DATABASE::"Dimension Value":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(DimensionValue);
                    PAGE.Run(PAGE::"Dimension Values", DimensionValue);
                end;
            DATABASE::"Dimension Value Combination":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(DimensionValueCombination);
                    MyDimValueCombinations.SetSelectedDimValueComb(DimensionValueCombination);
                    MyDimValueCombinations.Run();
                end;
            DATABASE::"Default Dimension":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then begin
                        RecRef.SetTable(DefaultDimension);
                        DefaultDimension.SetRange("Table ID", DefaultDimension."Table ID");
                        DefaultDimension.SetRange("No.", DefaultDimension."No.");
                    end;
                    PAGE.Run(PAGE::"Default Dimensions", DefaultDimension);
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    procedure ShowContextDimensions(RecID: RecordID) Result: Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowContextDimensions(RecID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case RecID.TableNo of
            DATABASE::"Sales Header":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(SalesHeader);
                    SalesHeader.ShowDocDim();
                end;
            DATABASE::"Sales Line":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(SalesLine);
                    if SalesLine.ShowDimensions() then
                        SalesLine.Modify();
                end;
            DATABASE::"Purchase Header":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(PurchaseHeader);
                    PurchaseHeader.ShowDocDim();
                end;
            DATABASE::"Purchase Line":
                begin
                    RecRef := RecID.GetRecord();
                    if RecRef.Find() then
                        RecRef.SetTable(PurchaseLine);
                    if PurchaseLine.ShowDimensions() then
                        PurchaseLine.Modify();
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Error Messages", 'OnDrillDownSource', '', false, false)]
    local procedure OnErrorMessageDrillDown(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
        if not IsHandled then
            if ErrorMessage."Table Number" in [DATABASE::Dimension .. DATABASE::"Default Dimension"] then
                case SourceFieldNo of
                    ErrorMessage.FieldNo("Context Record ID"):
                        IsHandled := ShowContextDimensions(ErrorMessage."Context Record ID");
                    ErrorMessage.FieldNo("Record ID"):
                        if Format(ErrorMessage."Record ID") = '' then
                            IsHandled := ShowContextDimensions(ErrorMessage."Context Record ID")
                        else
                            IsHandled := ShowDimensionsSetup(ErrorMessage."Record ID");
                end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchDim(PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDim(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowContextDimensions(RecID: RecordID; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchDimLinesOnAfterCheckPurchDimValuePostingLine(var TempPurchLine: Record "Purchase Line")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Error Messages", 'OnOpenRelatedRecord', '', false, false)]
    local procedure OnOpenRelatedRecord(ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    var
        PageManagement: Codeunit "Page Management";
    begin
        if ErrorMessage."Table Number" in [DATABASE::Dimension .. DATABASE::"Default Dimension"] then begin
            PageManagement.PageRun(ErrorMessage."Context Record ID");
            IsHandled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesDimLinesOnAfterCalcShouldCheckDimensions(SalesHeader: Record "Sales Header"; TempSalesLine: Record "Sales Line" temporary; var ShouldCheckDimensions: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimValuePostingOnAfterCreateDimTableIDs(RecordVariant: Variant; var TableIDArr: array[10] of Integer; var NumberArr: array[10] of Code[20])
    begin
    end;
}

