page 17347 "Person Income FSI"
{
    Caption = 'Person Income FSI';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Person Income FSI";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field(Calculation; Calculation)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Exclude from Calculation"; "Exclude from Calculation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Excluded Days"; "Excluded Days")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Recalculate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recalculate';
                    Image = Recalculate;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';

                    trigger OnAction()
                    begin
                        Recalculate;
                    end;
                }
            }
        }
    }
}

