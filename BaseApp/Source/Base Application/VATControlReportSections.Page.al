page 31102 "VAT Control Report Sections"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Control Report Sections';
    PageType = List;
    SourceTable = "VAT Control Report Section";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of VAT control report sections.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of VAT control report sections.';
                }
                field("Group By"; "Group By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup the group by the VAT entries in the VAT control report.';
                }
                field("Simplified Tax Doc. Sect. Code"; "Simplified Tax Doc. Sect. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of simplified tax document.';
                }
            }
        }
    }

    actions
    {
    }
}

