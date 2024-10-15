page 17411 "Payroll Base Amounts"
{
    Caption = 'Payroll Base Amounts';
    DataCaptionFields = "Element Code";
    PageType = List;
    SourceTable = "Payroll Base Amount";

    layout
    {
        area(content)
        {
            repeater(Control1210002)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Element Type Filter"; "Element Type Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Group Filter"; "Element Group Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code Filter"; "Element Code Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Base Filter"; "Income Tax Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("PF Base Filter"; "PF Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSI Base Filter"; "FSI Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Federal FMI Base Filter"; "Federal FMI Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Territorial FMI Base Filter"; "Territorial FMI Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSI Injury Base Filter"; "FSI Injury Base Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Type Filter"; "Posting Type Filter")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

