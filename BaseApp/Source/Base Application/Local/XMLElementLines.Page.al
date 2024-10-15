page 26587 "XML Element Lines"
{
    Caption = 'XML Element Lines';
    DataCaptionFields = "Report Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "XML Element Line";
    SourceTableView = SORTING("Report Code", "Sequence No.");

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                IndentationColumn = "Element NameIndent";
                IndentationControls = "Element Name";
                ShowCaption = false;
                field("Element Name"; Rec."Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = "Element NameEmphasize";
                    ToolTip = 'Specifies the element name associated with the XML element line.';
                }
                field(Indentation; Indentation)
                {
                    Editable = false;
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the parent line number associated with the XML element line.';
                    Visible = false;
                }
                field("Element Type"; Rec."Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type associated with the XML element line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML element line.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type associated with the XML element line.';
                }
                field("Link Type"; Rec."Link Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link type associated with the XML element line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';

                    trigger OnValidate()
                    var
                        XMLElementExpressionLine: Record "XML Element Expression Line";
                    begin
                        if "Source Type" <> xRec."Source Type" then begin
                            if "Source Type" <> "Source Type"::" " then
                                TestField("Link Type", "Link Type"::Value);
                            CheckReportDataExistence(Text005);

                            case xRec."Source Type" of
                                xRec."Source Type"::Expression:
                                    begin
                                        XMLElementExpressionLine.Reset();
                                        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
                                        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
                                        if XMLElementExpressionLine.FindFirst() then
                                            if Confirm(Text002) then begin
                                                XMLElementExpressionLine.DeleteAll();
                                                Value := '';
                                            end else
                                                Error('');
                                    end;
                                xRec."Source Type"::"Compound Element":
                                    begin
                                        XMLElementExpressionLine.Reset();
                                        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
                                        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
                                        if XMLElementExpressionLine.FindFirst() then
                                            if Confirm(Text004) then
                                                XMLElementExpressionLine.DeleteAll
                                            else
                                                Error('');
                                    end;
                                xRec."Source Type"::"Inserted Element",
                              xRec."Source Type"::"Individual Element":
                                    "Column Link No." := 0;
                            end;

                            if "Source Type" <> "Source Type"::Constant then
                                Value := '';

                            case "Source Type" of
                                "Source Type"::" ",
                              "Source Type"::Expression,
                              "Source Type"::Constant,
                              "Source Type"::"Individual Element",
                              "Source Type"::"Compound Element":
                                    "Column Link No." := 0;
                                "Source Type"::"Inserted Element":
                                    "Column Link No." := -10000;
                            end;

                            "Row Link No." := 0;
                        end;
                    end;
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the XML element line.';
                }
                field("Export Type"; Rec."Export Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the export type associated with the XML element line.';
                }
                field("Service Element"; Rec."Service Element")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the service element associated with the XML element line.';
                }
                field(Choice; Choice)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the XML element line is a choice line.';
                }
                field("OKEI Scaling"; Rec."OKEI Scaling")
                {
                    ToolTip = 'Specifies if OKEI scaling is associated with the XML element line.';
                    Visible = false;
                }
                field("Table Code"; Rec."Table Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table code associated with the XML element line.';

                    trigger OnValidate()
                    begin
                        TableCodeOnAfterValidate();
                    end;
                }
                field("Row Link No."; Rec."Row Link No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row link number of the XML element line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupRow;
                    end;
                }
                field("Column Link No."; Rec."Column Link No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column link number of the XML element line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupColumn;
                    end;
                }
                field("Excel Mapping Type"; Rec."Excel Mapping Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel mapping type associated with the XML element line.';
                }
                field("Excel Sheet Name"; Rec."Excel Sheet Name")
                {
                    ToolTip = 'Specifies the Microsoft Excel sheet name of the XML element line.';
                    Visible = false;
                }
                field("Excel Cell Name"; Rec."Excel Cell Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel cell name associated with the XML element line.';
                }
                field("Horizontal Cells Quantity"; Rec."Horizontal Cells Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the horizontal cells of the XML element line.';
                }
                field("Vertical Cells Quantity"; Rec."Vertical Cells Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the vertical cells of the XML element line.';
                }
                field("Vertical Cells Delta"; Rec."Vertical Cells Delta")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of rows between cells for the multi-cell XML element line.';
                }
                field("Fraction Digits"; Rec."Fraction Digits")
                {
                    ToolTip = 'Specifies the fraction digits of the XML element line.';
                    Visible = false;
                }
                field("XML Export Date Format"; Rec."XML Export Date Format")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Alignment; Alignment)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Pad Character"; Rec."Pad Character")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Template Data"; Rec."Template Data")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Element)
            {
                Caption = 'Element';
                action("Expression Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expression Lines';
                    Image = AdjustItemCost;
                    ShortCutKey = 'Shift+Ctrl+E';

                    trigger OnAction()
                    var
                        XMLElementExpressionLine: Record "XML Element Expression Line";
                        XMLElementExpressionLines: Page "XML Element Expression Lines";
                    begin
                        TestField("Source Type", "Source Type"::Expression);
                        XMLElementExpressionLine.FilterGroup(2);
                        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
                        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
                        XMLElementExpressionLine.FilterGroup(0);
                        XMLElementExpressionLines.SetTableView(XMLElementExpressionLine);
                        XMLElementExpressionLines.RunModal();
                    end;
                }
                action("Compound Element Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Compound Element Lines';
                    Image = ExplodeBOM;
                    ShortCutKey = 'Shift+Ctrl+C';

                    trigger OnAction()
                    begin
                        ShowCompoundElementLines;
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Move Up")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Up';
                    Image = MoveUp;
                    ShortCutKey = 'Shift+Ctrl+W';
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveUp();
                    end;
                }
                action("Move Down")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Down';
                    Image = MoveDown;
                    ShortCutKey = 'Shift+Ctrl+S';
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveDown();
                    end;
                }
                action("Move Right")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Right';
                    Image = NextRecord;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        MoveRight;
                    end;
                }
                action("Move Left")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Left';
                    Image = PreviousRecord;

                    trigger OnAction()
                    begin
                        MoveLeft;
                    end;
                }
                separator(Action1210038)
                {
                }
                action("Update Expression")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Expression';
                    Image = Refresh;
                    ToolTip = 'Update the related element expression.';

                    trigger OnAction()
                    begin
                        UpdateExpression;
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Move Up_Promoted"; "Move Up")
                {
                }
                actionref("Move Down_Promoted"; "Move Down")
                {
                }
                actionref("Move Right_Promoted"; "Move Right")
                {
                }
                actionref("Move Left_Promoted"; "Move Left")
                {
                }
                actionref("Expression Lines_Promoted"; "Expression Lines")
                {
                }
                actionref("Compound Element Lines_Promoted"; "Compound Element Lines")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        "Element NameIndent" := 0;
        ElementNameOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        XMLElementLine: Record "XML Element Line";
        SequenceNo: Integer;
        LineNo: Integer;
    begin
        XMLElementLine.SetRange("Report Code", "Report Code");
        if XMLElementLine.Find('+') then;
        LineNo := XMLElementLine."Line No." + 10000;

        XMLElementLine.SetCurrentKey("Report Code", "Sequence No.");

        if BelowxRec then begin
            if XMLElementLine.Find('+') then;
            "Sequence No." := XMLElementLine."Sequence No." + 1;
            "Line No." := LineNo;
        end else begin
            SequenceNo := xRec."Sequence No.";

            XMLElementLine.SetFilter("Sequence No.", '%1..', SequenceNo);
            if XMLElementLine.Find('+') then
                repeat
                    XMLElementLine."Sequence No." := XMLElementLine."Sequence No." + 1;
                    XMLElementLine.Modify();
                until XMLElementLine.Next(-1) = 0;

            "Line No." := LineNo;
            "Sequence No." := SequenceNo;
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not BelowxRec then begin
            Indentation := xRec.Indentation;
            "Parent Line No." := xRec."Parent Line No.";
            "Element Type" := xRec."Element Type";
        end;
    end;

    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReportTable: Record "Statutory Report Table";
        FormatVersion: Record "Format Version";
        Text000: Label 'Excel not found.';
        Text001: Label 'Excel template is already opened.';
        Text002: Label 'All related expression lines will be deleted. Proceed?';
        Text004: Label 'All related compound element lines will be deleted. Proceed?';
        Text005: Label '%1 cannot be modified because %2 %3 contains report data.';
        [InDataSet]
        "Element NameEmphasize": Boolean;
        [InDataSet]
        "Element NameIndent": Integer;

    [Scope('OnPrem')]
    procedure MoveUp()
    var
        UpperLine: Record "XML Element Line";
        SequenceNo: Integer;
        CurrLineNo: Integer;
    begin
        CheckReportDataExistence(Text005);
        UpperLine.SetCurrentKey("Report Code", "Sequence No.");
        UpperLine.SetRange("Report Code", "Report Code");
        UpperLine.SetFilter("Sequence No.", '..%1', "Sequence No." - 1);
        if UpperLine.FindLast() then begin
            SequenceNo := UpperLine."Sequence No.";
            UpperLine."Sequence No." := "Sequence No.";
            UpperLine.Modify();

            CurrLineNo := "Line No.";

            Get("Report Code", UpperLine."Line No.");
            "Sequence No." := UpperLine."Sequence No.";
            Modify();

            Get("Report Code", CurrLineNo);
            Indentation := UpperLine.Indentation;
            "Sequence No." := SequenceNo;
            Modify(true);

            UpperLine.Get("Report Code", CurrLineNo);
            UpperLine.Indentation := Indentation;
            UpperLine."Sequence No." := SequenceNo;
            UpperLine.Modify();
        end;

        UpdateLinks;
    end;

    [Scope('OnPrem')]
    procedure MoveDown()
    var
        LowerLine: Record "XML Element Line";
        SequenceNo: Integer;
        CurrLineNo: Integer;
    begin
        CheckReportDataExistence(Text005);
        LowerLine.SetCurrentKey("Report Code", "Sequence No.");
        LowerLine.SetRange("Report Code", "Report Code");
        LowerLine.SetFilter("Sequence No.", '%1..', "Sequence No." + 1);
        if LowerLine.FindFirst() then begin
            SequenceNo := LowerLine."Sequence No.";
            LowerLine."Sequence No." := "Sequence No.";
            LowerLine.Modify();

            CurrLineNo := "Line No.";

            Get("Report Code", LowerLine."Line No.");
            "Sequence No." := LowerLine."Sequence No.";
            Modify();

            Get("Report Code", CurrLineNo);
            Indentation := LowerLine.Indentation;
            "Sequence No." := SequenceNo;
            Modify(true);

            LowerLine.Get("Report Code", CurrLineNo);
            LowerLine.Indentation := Indentation;
            LowerLine."Sequence No." := SequenceNo;
            LowerLine.Modify();
        end;
        UpdateLinks;
    end;

    [Scope('OnPrem')]
    procedure MoveRight()
    begin
        CheckReportDataExistence(Text005);
        Indentation := Indentation + 1;
        Modify(true);
        UpdateLinks;
    end;

    [Scope('OnPrem')]
    procedure MoveLeft()
    begin
        CheckReportDataExistence(Text005);
        if Indentation > 0 then begin
            Indentation := Indentation - 1;
            Modify(true);
        end;
        UpdateLinks;
    end;

    [Scope('OnPrem')]
    procedure UpdateLinks()
    var
        XMLElementLine: Record "XML Element Line";
        ParentLine: Record "XML Element Line";
    begin
        ParentLine.SetCurrentKey("Report Code", "Sequence No.");
        ParentLine.SetRange("Report Code", "Report Code");

        XMLElementLine.SetCurrentKey("Report Code", "Sequence No.");
        XMLElementLine.SetRange("Report Code", "Report Code");
        if XMLElementLine.FindSet() then
            repeat
                if XMLElementLine.Indentation > 0 then begin
                    ParentLine.SetFilter("Sequence No.", '<%1', XMLElementLine."Sequence No.");
                    ParentLine.SetFilter(Indentation, '<%1', XMLElementLine.Indentation);
                    if ParentLine.FindLast() then begin
                        XMLElementLine."Parent Line No." := ParentLine."Line No.";
                        XMLElementLine.Modify();
                    end;
                end else begin
                    XMLElementLine."Parent Line No." := 0;
                    XMLElementLine.Modify();
                end;
            until XMLElementLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ShowCompoundElementLines()
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
        CompoundXMLElementLines: Page "Compound XML Element Lines";
    begin
        TestField("Source Type", "Source Type"::"Compound Element");
        XMLElementExpressionLine.FilterGroup(2);
        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
        XMLElementExpressionLine.FilterGroup(0);
        CompoundXMLElementLines.SetTableView(XMLElementExpressionLine);
        CompoundXMLElementLines.RunModal();
    end;

    local procedure TableCodeOnAfterValidate()
    begin
        if "Table Code" <> '' then begin
            CurrPage.SaveRecord();
            UpdateTableCode("Table Code");
            CurrPage.Update();
        end;
    end;

    local procedure ElementNameOnFormat()
    begin
        "Element NameIndent" := Indentation;
        "Element NameEmphasize" := "Element Type" = "Element Type"::Complex;
    end;
}

