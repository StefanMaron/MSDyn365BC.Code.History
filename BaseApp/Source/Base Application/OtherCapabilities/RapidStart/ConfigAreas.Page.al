page 8631 "Config. Areas"
{
    Caption = 'Config. Areas';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Config. Line";
    SourceTableView = WHERE("Line Type" = FILTER(<> Table));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the type of the configuration package line.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the line type.';
                }
                field(GetNoTables; GetNoTables())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tables';
                    ToolTip = 'Specifies how many tables the configuration package contains.';
                }
                field(Completion; Progress)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Completion';
                    ExtendedDatatype = Ratio;
                    MaxValue = 100;
                    MinValue = 0;
                    ToolTip = 'Specifies how much of the table configuration is completed.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        case "Line Type" of
            "Line Type"::Group:
                NameIndent := 1;
        end;

        NameEmphasize := (NameIndent = 0);

        Progress := GetProgress();
    end;

    var
        NameIndent: Integer;
        NameEmphasize: Boolean;
        Progress: Integer;
}

