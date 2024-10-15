page 27043 "SAT Units Of Measure"
{
    Caption = 'SAT Units of Measure';
    PageType = List;
    SourceTable = "SAT Unit of Measure";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SAT UofM Code"; "SAT UofM Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for this entry according to the SAT unit of measure definition.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for this entry according to the SAT unit of measure definition.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this entry according to the SAT unit of measure definition.';
                }
                field(Symbol; Symbol)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a symbol for this entry according to the SAT unit of measure definition.';
                }
            }
        }
    }

    actions
    {
    }
}

