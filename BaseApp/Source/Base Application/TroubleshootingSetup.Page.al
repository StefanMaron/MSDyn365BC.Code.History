page 5993 "Troubleshooting Setup"
{
    Caption = 'Troubleshooting Setup';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Troubleshooting Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of troubleshooting issue.';
                    Visible = TypeVisible;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoVisible;
                }
                field("Troubleshooting No."; "Troubleshooting No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the troubleshooting issue.';
                }
                field("Troubleshooting Description"; "Troubleshooting Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies a description of the troubleshooting issue.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("T&roublesh.")
            {
                Caption = 'T&roublesh.';
                Image = Setup;
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        Clear(Tblshtg);
                        if TblshtgHeader.Get("Troubleshooting No.") then
                            if "No." <> '' then begin
                                Tblshtg.SetCaption(Format(Type), "No.");
                                Tblshtg.SetRecord(TblshtgHeader);
                            end;

                        Tblshtg.Run;
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        NoVisible := true;
        TypeVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Validate(Type, RecType);
        Validate("No.", No);
    end;

    trigger OnOpenPage()
    begin
        TypeVisible := GetFilter(Type) = '';
        NoVisible := GetFilter("No.") = '';

        if (GetFilter(Type) <> '') and (GetFilter("No.") <> '') then begin
            RecType := GetRangeMin(Type);
            No := GetRangeMin("No.");
        end;
    end;

    var
        TblshtgHeader: Record "Troubleshooting Header";
        Tblshtg: Page Troubleshooting;
        [InDataSet]
        TypeVisible: Boolean;
        [InDataSet]
        NoVisible: Boolean;
        RecType: Option;
        No: Code[20];
}

