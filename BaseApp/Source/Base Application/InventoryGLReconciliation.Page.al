page 5845 "Inventory - G/L Reconciliation"
{
    AdditionalSearchTerms = 'general ledger reconcile inventory';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - G/L Reconciliation';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Dimension Code Buffer";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        InvtReportHeader.SetFilter("Posting Date Filter", DateFilter);
                        DateFilter := InvtReportHeader.GetFilter("Posting Date Filter");
                        DateFilterOnAfterValidate;
                    end;
                }
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies which items the information is shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        Item.SetRange(Type, Item.Type::Inventory);
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal = ACTION::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Text := Item."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        TestWarning;
                        ItemFilterOnAfterValidate;
                    end;
                }
                field(LocationFilter; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies which item locations the information is shown for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        Locations: Page "Location List";
                    begin
                        Locations.SetTableView(Location);
                        Locations.LookupMode := true;
                        if Locations.RunModal = ACTION::LookupOK then begin
                            Locations.GetRecord(Location);
                            Text := Location.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        TestWarning;
                        LocationFilterOnAfterValidate;
                    end;
                }
                field(Show; ShowWarning)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Warning';
                    Editable = ShowEditable;
                    ToolTip = 'Specifies that a messages will be shown in the Warning field of the grid if there are any discrepancies between the inventory totals and G/L totals. If you choose the Warning field, the program gives you more information on what the warning means.';

                    trigger OnValidate()
                    begin
                        ShowWarningOnAfterValidate;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show Matrix")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View the data overview according to the selected filters and options.';

                trigger OnAction()
                var
                    MatrixForm: Page "Inventory - G/L Recon Matrix";
                    i: Integer;
                begin
                    Clear(MatrixForm);
                    Clear(MatrixRecords);
                    Clear(MATRIX_CaptionSet);

                    with InvtReportHeader do begin
                        if "Column Option" = "Line Option"::"Balance Sheet" then begin
                            if (ItemFilter = '') and (LocationFilter = '') then begin
                                if ShowWarning then
                                    ColIntegerLine.SetRange(Number, 1, 7)
                                else
                                    ColIntegerLine.SetRange(Number, 1, 6)
                            end else
                                ColIntegerLine.SetRange(Number, 1, 4)
                        end else
                            if "Column Option" = "Line Option"::"Income Statement" then
                                if (ItemFilter = '') and (LocationFilter = '') then begin
                                    if ShowWarning then
                                        ColIntegerLine.SetRange(Number, 1, 18)
                                    else
                                        ColIntegerLine.SetRange(Number, 1, 17)
                                end else
                                    ColIntegerLine.SetRange(Number, 1, 15);
                        i := 1;

                        if FindRec("Column Option", MatrixRecords[i], '-', false) then begin
                            MATRIX_CaptionSet[i] := MatrixRecords[i].Name;
                            i := i + 1;
                            while NextRec("Column Option", MatrixRecords[i], 1, false) <> 0 do begin
                                MATRIX_CaptionSet[i] := MatrixRecords[i].Name;
                                i := i + 1;
                            end;
                        end;
                    end;
                    if ShowWarning then
                        MATRIX_CurrentNoOfColumns := i
                    else
                        MATRIX_CurrentNoOfColumns := i - 1;

                    MatrixForm.Load(MATRIX_CaptionSet, MatrixRecords, MATRIX_CurrentNoOfColumns, ShowWarning,
                      DateFilter, ItemFilter, LocationFilter);
                    MatrixForm.RunModal;
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        with InvtReportHeader do begin
            if "Line Option" = "Line Option"::"Balance Sheet" then begin
                if (ItemFilter = '') and (LocationFilter = '') then begin
                    if ShowWarning then
                        RowIntegerLine.SetRange(Number, 1, 7)
                    else
                        RowIntegerLine.SetRange(Number, 1, 6)
                end else
                    RowIntegerLine.SetRange(Number, 1, 4)
            end else
                if "Line Option" = "Line Option"::"Income Statement" then
                    if (ItemFilter = '') and (LocationFilter = '') then begin
                        if ShowWarning then
                            RowIntegerLine.SetRange(Number, 1, 18)
                        else
                            RowIntegerLine.SetRange(Number, 1, 17)
                    end else
                        RowIntegerLine.SetRange(Number, 1, 15);
            exit(FindRec("Line Option", Rec, Which, true));
        end;
    end;

    trigger OnInit()
    begin
        ShowEditable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(InvtReportHeader."Line Option", Rec, Steps, true));
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        TestWarning;
        InvtReportHeader.SetFilter("Item Filter", ItemFilter);
        InvtReportHeader.SetFilter("Location Filter", LocationFilter);
        InvtReportHeader.SetFilter("Posting Date Filter", DateFilter);
        InvtReportHeader."Show Warning" := ShowWarning;

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Text004;
            ColumnDimCode := Text005;
        end;
        InvtReportHeader."Line Option" := DimCodeToOption(LineDimCode);
        InvtReportHeader."Column Option" := DimCodeToOption(ColumnDimCode);
    end;

    var
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        GLSetup: Record "General Ledger Setup";
        InvtReportHeader: Record "Inventory Report Header";
        InvtReportEntry: Record "Inventory Report Entry" temporary;
        RowIntegerLine: Record "Integer";
        ColIntegerLine: Record "Integer";
        MATRIX_CaptionSet: array[32] of Text[100];
        MATRIX_CurrentNoOfColumns: Integer;
        LineDimCode: Text[20];
        ColumnDimCode: Text[20];
        DateFilter: Text[30];
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        Text004: Label 'Income Statement';
        Text005: Label 'Balance Sheet';
        ShowWarning: Boolean;
        [InDataSet]
        ShowEditable: Boolean;

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    begin
        case DimCode of
            '':
                exit(-1);
            Text005:
                exit(0);
            Text004:
                exit(1);
            else
                exit(-1);
        end;
    end;

    local procedure FindRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; IsRow: Boolean): Boolean
    var
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := RowIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := ColIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; IsRow: Boolean): Integer
    var
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := RowIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := ColIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopyDimValueToBuf(var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer"; IsRow: Boolean)
    begin
        with InvtReportEntry do
            case true of
                ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Balance Sheet") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Balance Sheet") and not IsRow):
                    case TheDimValue.Number of
                        1:
                            InsertRow('1', FieldCaption(Inventory), 0, false, TheDimCodeBuf);
                        2:
                            InsertRow('2', FieldCaption("Inventory (Interim)"), 0, false, TheDimCodeBuf);
                        3:
                            InsertRow('3', FieldCaption("WIP Inventory"), 0, false, TheDimCodeBuf);
                        4:
                            InsertRow('4', FieldCaption(Total), 0, true, TheDimCodeBuf);
                        5:
                            InsertRow('5', FieldCaption("G/L Total"), 0, true, TheDimCodeBuf);
                        6:
                            InsertRow('6', FieldCaption(Difference), 0, true, TheDimCodeBuf);
                        7:
                            InsertRow('7', FieldCaption(Warning), 0, true, TheDimCodeBuf);
                    end;
                ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Income Statement") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Income Statement") and not IsRow):
                    case TheDimValue.Number of
                        1:
                            InsertRow('1', FieldCaption("Inventory To WIP"), 0, false, TheDimCodeBuf);
                        2:
                            InsertRow('2', FieldCaption("WIP To Interim"), 0, false, TheDimCodeBuf);
                        3:
                            InsertRow('3', FieldCaption("COGS (Interim)"), 0, false, TheDimCodeBuf);
                        4:
                            InsertRow('4', FieldCaption("Direct Cost Applied"), 0, false, TheDimCodeBuf);
                        5:
                            InsertRow('5', FieldCaption("Overhead Applied"), 0, false, TheDimCodeBuf);
                        6:
                            InsertRow('6', FieldCaption("Inventory Adjmt."), 0, false, TheDimCodeBuf);
                        7:
                            InsertRow('7', FieldCaption("Invt. Accrual (Interim)"), 0, false, TheDimCodeBuf);
                        8:
                            InsertRow('8', FieldCaption(COGS), 0, false, TheDimCodeBuf);
                        9:
                            InsertRow('9', FieldCaption("Purchase Variance"), 0, false, TheDimCodeBuf);
                        10:
                            InsertRow('10', FieldCaption("Material Variance"), 0, false, TheDimCodeBuf);
                        11:
                            InsertRow('11', FieldCaption("Capacity Variance"), 0, false, TheDimCodeBuf);
                        12:
                            InsertRow('12', FieldCaption("Subcontracted Variance"), 0, false, TheDimCodeBuf);
                        13:
                            InsertRow('13', FieldCaption("Capacity Overhead Variance"), 0, false, TheDimCodeBuf);
                        14:
                            InsertRow('14', FieldCaption("Mfg. Overhead Variance"), 0, false, TheDimCodeBuf);
                        15:
                            InsertRow('15', FieldCaption(Total), 0, true, TheDimCodeBuf);
                        16:
                            InsertRow('16', FieldCaption("G/L Total"), 0, true, TheDimCodeBuf);
                        17:
                            InsertRow('17', FieldCaption(Difference), 0, true, TheDimCodeBuf);
                        18:
                            InsertRow('18', FieldCaption(Warning), 0, true, TheDimCodeBuf);
                    end;
            end
    end;

    local procedure InsertRow(Code1: Code[10]; Name1: Text[80]; Indentation1: Integer; Bold1: Boolean; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := Code1;
            Name := CopyStr(Name1, 1, MaxStrLen(Name));
            Indentation := Indentation1;
            "Show in Bold" := Bold1;
        end;
    end;

    local procedure TestWarning()
    begin
        ShowEditable := true;
        if ShowWarning then begin
            if (ItemFilter <> '') or (LocationFilter <> '') then begin
                ShowWarning := false;
                ShowEditable := false;
            end;
        end else
            if (ItemFilter <> '') or (LocationFilter <> '') then begin
                ShowWarning := false;
                ShowEditable := false;
            end;
    end;

    local procedure LocationFilterOnAfterValidate()
    begin
        InvtReportHeader.SetFilter("Location Filter", LocationFilter);
        CurrPage.Update;
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure ItemFilterOnAfterValidate()
    begin
        InvtReportHeader.SetFilter("Item Filter", ItemFilter);
        CurrPage.Update;
    end;

    local procedure ShowWarningOnAfterValidate()
    begin
        InvtReportHeader."Show Warning" := ShowWarning;
        CurrPage.Update;
    end;
}

