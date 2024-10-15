page 31068 "VIES Declarations"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VIES Declarations';
    CardPageID = "VIES Declaration";
    Editable = false;
    PageType = List;
    SourceTable = "VIES Declaration Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1220009)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the VIES Declaration.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Declaration Type"; "Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration type for the declaration header (normal, corrective, corrective-supplementary).';
                }
                field("Corrected Declaration No."; "Corrected Declaration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the existing VIES declaration that needs to be corrected.';
                }
                field("Declaration Period"; "Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies declaration Period (month, quarter).';
                }
                field("Period No."; "Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT period.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of report';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of reverse charge';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
            }
        }
    }

    actions
    {
    }
}

