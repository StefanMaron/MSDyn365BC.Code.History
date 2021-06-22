page 5840 "Standard Cost Worksheet Names"
{
    Caption = 'Standard Cost Worksheet Names';
    PageType = List;
    SourceTable = "Standard Cost Worksheet Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the worksheet.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the worksheet.';
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
        area(processing)
        {
            action(EditWorksheet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Worksheet';
                Image = OpenWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open the related worksheet.';

                trigger OnAction()
                begin
                    StdCostWksh."Standard Cost Worksheet Name" := Name;
                    PAGE.Run(PAGE::"Standard Cost Worksheet", StdCostWksh);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not StdCostWkshName.FindFirst then begin
            StdCostWkshName.Init();
            StdCostWkshName.Name := Text001;
            StdCostWkshName.Description := Text001;
            StdCostWkshName.Insert();
        end;
    end;

    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
        Text001: Label 'Default';
        StdCostWksh: Record "Standard Cost Worksheet";
}

