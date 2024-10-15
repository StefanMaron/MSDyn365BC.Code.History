page 26568 "Stat. Report Excel Sheets"
{
    Caption = 'Stat. Report Excel Sheets';
    Editable = false;
    PageType = List;
    SourceTable = "Stat. Report Excel Sheet";
    SourceTableView = SORTING("Report Code", "Table Code", "Report Data No.", "Sequence No.");

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Sheet Name"; Rec."Sheet Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the statutory report Excel sheet.';
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new page of the statutory report Excel sheet.';
                }
            }
        }
    }

    actions
    {
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
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveDown();
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        StatutoryReportTable: Record "Statutory Report Table";
        Sheet: Record "Stat. Report Excel Sheet";
    begin
        Sheet.SetCurrentKey("Report Code", "Table Code", "Report Data No.", "Sequence No.");
        Sheet.SetRange("Report Code", "Report Code");
        Sheet.SetRange("Report Data No.", "Report Data No.");
        Sheet.SetRange("Table Code", "Table Code");
        if Sheet.FindLast() then;
        "Sequence No." := Sheet."Sequence No." + 1;
        StatutoryReportTable.Get("Report Code", "Table Code");
        "Parent Sheet Name" := StatutoryReportTable."Excel Sheet Name";
    end;

    [Scope('OnPrem')]
    procedure MoveUp()
    var
        UpperSheet: Record "Stat. Report Excel Sheet";
        SequenceNo: Integer;
    begin
        if "Parent Sheet Name" <> '' then begin
            UpperSheet.SetCurrentKey("Report Code", "Table Code", "Report Data No.", "Sequence No.");
            UpperSheet.SetRange("Report Code", "Report Code");
            UpperSheet.SetRange("Report Data No.", "Report Data No.");
            UpperSheet.SetRange("Table Code", "Table Code");
            UpperSheet.SetFilter("Parent Sheet Name", '<>''''');
            UpperSheet.SetFilter("Sequence No.", '..%1', "Sequence No." - 1);
            if UpperSheet.FindLast() then begin
                SequenceNo := UpperSheet."Sequence No.";
                UpperSheet."Sequence No." := "Sequence No.";
                UpperSheet.Modify();

                "Sequence No." := SequenceNo;
                Modify();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure MoveDown()
    var
        LowerSheet: Record "Stat. Report Excel Sheet";
        SequenceNo: Integer;
    begin
        if "Parent Sheet Name" <> '' then begin
            LowerSheet.SetCurrentKey("Report Code", "Table Code", "Report Data No.", "Sequence No.");
            LowerSheet.SetRange("Report Code", "Report Code");
            LowerSheet.SetRange("Report Data No.", "Report Data No.");
            LowerSheet.SetRange("Table Code", "Table Code");
            LowerSheet.SetFilter("Parent Sheet Name", '<>''''');
            LowerSheet.SetFilter("Sequence No.", '%1..', "Sequence No." + 1);
            if LowerSheet.FindFirst() then begin
                SequenceNo := LowerSheet."Sequence No.";
                LowerSheet."Sequence No." := "Sequence No.";
                LowerSheet.Modify();

                "Sequence No." := SequenceNo;
                Modify();
            end;
        end;
    end;
}

