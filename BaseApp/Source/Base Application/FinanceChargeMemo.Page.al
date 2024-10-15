page 446 "Finance Charge Memo"
{
    Caption = 'Finance Charge Memo';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Memo,Navigate';
    SourceTable = "Finance Charge Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the customer you want to create a finance charge memo for.';

                    trigger OnValidate()
                    begin
                        Customer.GetPrimaryContact("Customer No.", PrimaryContact);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer the finance charge memo is for.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the customer the finance charge memo is for.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the finance charge memo is for.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the finance charge memo is for.';
                }
                field(ContactPhoneNo; PrimaryContact."Phone No.")
                {
                    Caption = 'Phone No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the customer contact person the finance charge is for.';
                }
                field(ContactMobilePhoneNo; PrimaryContact."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the customer contact person the finance charge is for.';
                }
                field(ContactEmail; PrimaryContact."E-Mail")
                {
                    Caption = 'Email';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the email address of the customer contact person the finance charge is for.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the finance charge memo should be issued.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
            }
            part(FinChrgMemoLines; "Finance Charge Memo Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Finance Charge Memo No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies when payment of the amount on the finance charge memo is due.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code of the finance charge memo.';

                    trigger OnAssistEdit()
                    begin
                        Rec.TestField("Posting Date");
                        ChangeExchangeRate.SetParameter(
                          Rec."Currency Code",
                          CurrExchRate.ExchangeRate(Rec."Posting Date", Rec."Currency Code"),
                          Rec."Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal = ACTION::OK then;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; "Company Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
                field(GLN; Rec.GLN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the global location number of the customer.';
                }
                field("Account Code"; Rec."Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account code of the customer.';

                    trigger OnValidate()
                    begin
                        AccountCodeOnAfterValidate;
                    end;
                }
                field("E-Invoice"; Rec."E-Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the customer is part of the EHF system and requires an electronic finance charge memo.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPostingGroupEditable;
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Memo")
            {
                Caption = '&Memo';
                Image = Notes;
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all finance charges that exist.';

                    trigger OnAction()
                    begin
                        FinChrgMemoHeader.Copy(Rec);
                        if PAGE.RunModal(0, FinChrgMemoHeader) = ACTION::LookupOK then
                            Rec := FinChrgMemoHeader;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Fin. Charge Comment Sheet";
                    RunPageLink = Type = CONST("Finance Charge Memo"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                separator(Action32)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Finance Charge Memo Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateFinanceChargeMemos)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Finance Charge Memos';
                    Ellipsis = true;
                    Image = CreateFinanceChargememo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create finance charge memos for one or more customers with overdue payments.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Create Finance Charge Memos");
                    end;
                }
                action(SuggestFinChargeMemoLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Fin. Charge Memo Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    ToolTip = 'Create finance charge memo lines in existing finance charge memos for any overdue payments based on information in the Finance Charge Memo window.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        REPORT.RunModal(REPORT::"Suggest Fin. Charge Memo Lines", true, false, FinChrgMemoHeader);
                    end;
                }
                action(UpdateFinChargeText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Finance Charge Text';
                    Ellipsis = true;
                    Image = RefreshText;
                    ToolTip = 'Replace the beginning and ending text that has been defined for the related finance charge terms with those from different terms.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        REPORT.RunModal(REPORT::"Update Finance Charge Text", true, false, FinChrgMemoHeader);
                    end;
                }
            }
            group("&Issuing")
            {
                Caption = '&Issuing';
                Image = Add;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        FinChrgMemoHeader.PrintRecords();
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the specified finance charge entries according to your specifications in the Finance Charge Terms window. This specification determines whether interest and/or additional fees are posted to the customer''s account and the general ledger.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        REPORT.RunModal(REPORT::"Issue Finance Charge Memos", true, true, FinChrgMemoHeader);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Finance Charge Memo Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finance Charge Memo Nos.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo Nos.";
                ToolTip = 'View or edit the finance charge memo numbers that are set up. ';
            }
            action("Finance Charge Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finance Charge Memo';
                Image = FinChargeMemo;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo";
                ToolTip = 'Create a new finance charge memo.';
            }
            action("Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if (not DocNoVisible) and (Rec."No." = '') then
            Rec.SetCustomerFromFilter();
    end;

    trigger OnOpenPage()
    begin
        SetDocNoVisible();
        SetPostingGroupEditable();
    end;

    trigger OnAfterGetRecord()
    begin
        Customer.GetPrimaryContact(Rec."Customer No.", PrimaryContact);
    end;

    var
        PrimaryContact: Record Contact;
        Customer: Record Customer;
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        CurrExchRate: Record "Currency Exchange Rate";
        SalesSetup: Record "Sales & Receivables Setup";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocNoVisible: Boolean;
        IsPostingGroupEditable: Boolean;

    local procedure AccountCodeOnAfterValidate()
    begin
        CurrPage.FinChrgMemoLines.PAGE.UpdatePage(true);
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::FinChMemo, Rec."No.");
    end;

    procedure SetPostingGroupEditable()
    begin
        SalesSetup.GetRecordOnce();
        IsPostingGroupEditable := SalesSetup."Allow Multiple Posting Groups";
    end;
}

