page 1271 "OCR Service Document Templates"
{
    Caption = 'OCR Service Document Templates';
    PageType = List;
    SourceTable = "OCR Service Document Template";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the OCR document template.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the OCR document template.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(GetDefaults)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update Document Template List';
                Image = Template;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Check for new document templates that the OCR service supports, and add them to the list.';

                trigger OnAction()
                var
                    OCRServiceMgt: Codeunit "OCR Service Mgt.";
                begin
                    OCRServiceMgt.UpdateOcrDocumentTemplates;
                end;
            }
        }
    }
}

