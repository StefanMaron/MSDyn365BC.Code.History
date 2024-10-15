page 15000010 "Remittance Agreement Overview"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Remittance Agreement Overview';
    CardPageID = "Remittance Agreement Card";
    Editable = false;
    PageType = List;
    SourceTable = "Remittance Agreement";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Sets a unique ID for the remittance agreement.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the remittance agreement.';
                }
                field("Payment System"; "Payment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the available payment systems.';
                }
            }
        }
    }

    actions
    {
    }
}

