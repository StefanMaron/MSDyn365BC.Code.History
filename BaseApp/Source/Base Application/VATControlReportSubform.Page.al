#if not CLEAN17
page 31103 "VAT Control Report Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "VAT Control Report Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("VAT Control Rep. Section Code"; "VAT Control Rep. Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies section code for VAT control report.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor entry''s posting date.';
                }
                field("VAT Date"; "VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT date. This date must be shown on the VAT statement.';
                }
                field("Original Document VAT Date"; "Original Document VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT date of the original document.';
                }
                field("Bill-to/Pay-to No."; "Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the partner''s number (customer or vendor).';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
                field("Registration No."; "Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of customer or vendor.';
                }
                field("Tax Registration No."; "Tax Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the secondary VAT registration number for the partner.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of sales or purchase.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the vendor uses on the invoice they sent to you or number of receipt.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of user setup lines list';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a VAT business posting group code.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT base of document.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount of document.';
                }
                field("VAT Rate"; "VAT Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies typ of VAT rate - base, reduced or reduced 2.';
                }
                field("Commodity Code"; "Commodity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies code from reverse charge.';
                }
                field("Supplies Mode Code"; "Supplies Mode Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies supplies mode code from VAT layer.';
                }
                field("Corrections for Bad Receivable"; "Corrections for Bad Receivable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the receivable is in insolvency proceedings or bad receivable.';
                }
                field("Ratio Use"; "Ratio Use")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document which the ratio use was used in.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of whse. net change template list';
                }
                field("Birth Date"; "Birth Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s birth date in the cases you sale investment gold.';
                }
                field("Place of stay"; "Place of stay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s address in the cases you sale investment gold.';
                }
                field("Exclude from Export"; "Exclude from Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the line should be excluded from export.';
                }
                field("Closed by Document No."; "Closed by Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number whitch the document was closed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Navigate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                    trigger OnAction()
                    begin
                        Navigate;
                    end;
                }
                action("Change Section")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Section';
                    Image = Change;
                    ToolTip = 'Function for changing the section code.';

                    trigger OnAction()
                    var
                        VATControlReportLine: Record "VAT Control Report Line";
                    begin
                        CurrPage.SetSelectionFilter(VATControlReportLine);
                        VATControlReportLine.ChangeVATControlRepSection();
                    end;
                }
            }
        }
    }
}
#endif