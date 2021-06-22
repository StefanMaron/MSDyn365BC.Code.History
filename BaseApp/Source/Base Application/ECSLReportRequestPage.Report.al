report 323 "ECSL Report Request Page"
{
    Caption = 'ECSL Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field("""VAT Report Header"".""Period Year"""; "VAT Report Header"."Period Year")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Period Year';
                    ToolTip = 'Specifies the period for the EU Sales Report.';
                }
                field("""VAT Report Header"".""Period Type"""; "VAT Report Header"."Period Type")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Period Type';
                    ToolTip = 'Specifies the type of period for the EU Sales Report you want to view.';
                }
                field("""VAT Report Header"".""Period No."""; "VAT Report Header"."Period No.")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Period No.';
                    ToolTip = 'Specifies the number of the period for the EU Sales Report you want to view.';
                }
                field("""VAT Report Header"".""Start Date"""; "VAT Report Header"."Start Date")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Start Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the start date for the EU Sales Report you want to view.';
                }
                field("""VAT Report Header"".""End Date"""; "VAT Report Header"."End Date")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'End Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the end date for the report.';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }
}

