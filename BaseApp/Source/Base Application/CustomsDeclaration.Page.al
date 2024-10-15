page 12416 "Customs Declaration"
{
    Caption = 'Customs Declaration';
    PageType = Document;
    SourceTable = "CD No. Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Country/Region of Origin Code"; "Country/Region of Origin Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';

                    trigger OnValidate()
                    begin
                        if "Country/Region of Origin Code" <> xRec."Country/Region of Origin Code" then
                            CurrPage.Lines.PAGE.UpdateForm;
                    end;
                }
                field("Declaration Date"; "Declaration Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration date associated with this custom declaration header.';
                }
            }
            part(Lines; "Customs Declaration Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "CD Header No." = FIELD("No.");
                SubPageView = SORTING("CD Header No.", "CD No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("N&avigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'N&avigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    CurrPage.Lines.PAGE.Navigate;
                end;
            }
        }
    }
}

