page 5736 "Item References"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item References';
    DataCaptionFields = "Reference Type No.";
    Editable = true;
    PageType = List;
    SourceTable = "Item Reference";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the referenced item number. If you enter a reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the reference number on a sales or purchase document.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number on the item card from which you opened the Item Reference Entries window.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item that is linked to this reference.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the item that is linked to this reference.';
                    Visible = false;
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
        area(Processing)
        {
#if not CLEAN19
            action(CopyItemCrossReferences)
            {
                ApplicationArea = Suite, ItemReferences;
                Caption = 'Copy Item Cross References';
                Image = CopySerialNo;
                RunObject = Report "Copy Item Cross References";
                ToolTip = 'Copy Item Cross Reference table records that do not exist in Item Reference table.';
                ObsoleteState = Pending;
                ObsoleteTag = '19.0';
                ObsoleteReason = 'Will be removed along with Item Cross Reference table.';
            }
#endif
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

#if not CLEAN19
                actionref(CopyItemCrossReferences_Promoted; CopyItemCrossReferences)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Will be removed along with Item Cross Reference table.';
                    ObsoleteTag = '19.0';
                }
#endif
            }
        }
    }
}

