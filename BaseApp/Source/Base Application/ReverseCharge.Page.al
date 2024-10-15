page 31098 "Reverse Charge"
{
    Caption = 'Reverse Charge';
    PageType = Card;
    SourceTable = "Reverse Charge Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the reverse charge.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        AssistEdit(xRec);
                    end;
                }
                field("Declaration Period"; "Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies declaration Period (month, quarter).';
                }
                field("Declaration Type"; "Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies type of declaration.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of vat control report';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
                field("Tax Office No."; "Tax Office No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax office number for reporting.';
                }
                field("Tax Office Region No."; "Tax Office Region No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of tax office region.';
                }
                field("Statement Type"; "Statement Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement type (recaputulative or corrective).';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of vat control report';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
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
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reverse charge declaration start date. The field is calculated based on the Trade Type, Period No., and financial Year.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies end date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field("VAT Base Amount (LCY)"; "VAT Base Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies VAT base amount of advance. The amount is in the local currency.';
                }
                field("Number of Lines"; "Number of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of lines.';
                }
                field("Part Period From"; "Part Period From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration start date.';
                }
                field("Part Period To"; "Part Period To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration last date.';
                }
            }
            part(Lines; "Reverse Charge Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Reverse Charge No." = FIELD("No.");
                UpdatePropagation = Both;
            }
            group(Address)
            {
                Caption = 'Address';
                field("Country/Region Name"; "Country/Region Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city for the tax office.';
                }
                field("House No."; "House No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s house number.';
                }
                field("Municipality No."; "Municipality No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the municipality number fot the tax office.';
                }
                field(Street; Street)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies street of company';
                }
            }
            group(Persons)
            {
                Caption = 'Persons';
                field("Authorized Employee No."; "Authorized Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies authorized employee.';
                }
                field("Filled by Employee No."; "Filled by Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for the employee who filled the reverse charge declaration.';
                }
                field("Natural Employee No."; "Natural Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies employee number for the natural employee.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220033; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1220032; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest Reverse Charge")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Reverse Charge';
                    Ellipsis = true;
                    Image = SuggestLines;
                    RunPageOnRec = true;
                    ToolTip = 'Opens suggest reverse charge lines';

                    trigger OnAction()
                    var
                        ReverseChargeHdr: Record "Reverse Charge Header";
                    begin
                        TestField(Status, Status::Open);
                        ReverseChargeHdr := Rec;
                        ReverseChargeHdr.SetRecFilter;
                        REPORT.RunModal(REPORT::"Suggest Reverse Charge Lines", true, false, ReverseChargeHdr);
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Ellipsis = true;
                    Image = ExportElectronicDocument;
                    ToolTip = 'Allows the reverse charge export to xml.';

                    trigger OnAction()
                    var
                        ReverseChargeHdr: Record "Reverse Charge Header";
                    begin
                        TestField(Status, Status::Released);
                        ReverseChargeHdr := Rec;
                        ReverseChargeHdr.SetRecFilter;
                        XMLPORT.Run(XMLPORT::"Reverse Charge Export", true, false, ReverseChargeHdr);
                    end;
                }
            }
            group(Release)
            {
                Caption = 'Release';
                Image = Release;
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release vat control report';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Release Reverse Charge", Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have tha Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseReverseCharge: Codeunit "Release Reverse Charge";
                    begin
                        ReleaseReverseCharge.Reopen(Rec);
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ReverseChargeHdr: Record "Reverse Charge Header";
                begin
                    ReverseChargeHdr := Rec;
                    ReverseChargeHdr.SetRecFilter;
                    REPORT.RunModal(REPORT::"Reverse Charge Statement", true, true, ReverseChargeHdr);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDocNoVisible;
    end;

    var
        DocNoVisible: Boolean;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option "VIES Declaration","Reverse Charge";
    begin
        DocNoVisible := DocumentNoVisibility.StatReportingDocumentNoIsVisible(DocType::"Reverse Charge", "No.");
    end;
}

