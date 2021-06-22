page 9322 "Service Contract Quotes"
{
    ApplicationArea = Service;
    Caption = 'Service Contract Quotes';
    CardPageID = "Service Contract Quote";
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Header";
    SourceTableView = WHERE("Contract Type" = CONST(Quote));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract or service contract quote.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the service contract or contract quote.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the service items in the service contract/contract quote.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer in the service contract.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service contract expires.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Bill-to Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
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
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Contract"),
                                  "Table Subtype" = FIELD("Contract Type"),
                                  "No." = FIELD("Contract No."),
                                  "Table Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action("Service Dis&counts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Dis&counts';
                    Image = Discount;
                    RunObject = Page "Contract/Service Discounts";
                    RunPageLink = "Contract Type" = FIELD("Contract Type"),
                                  "Contract No." = FIELD("Contract No.");
                    ToolTip = 'View or edit the discounts that you grant for the contract on spare parts in particular service item groups, the discounts on resource hours for resources in particular resource groups, and the discounts on particular service costs.';
                }
                action("Service &Hours")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Hours';
                    Image = ServiceHours;
                    RunObject = Page "Service Hours";
                    RunPageLink = "Service Contract No." = FIELD("Contract No."),
                                  "Service Contract Type" = FILTER(Quote);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                action("&Filed Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = '&Filed Contract Quotes';
                    Image = Quote;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = FIELD("Contract Type"),
                                  "Contract No. Relation" = FIELD("Contract No.");
                    RunPageView = SORTING("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  ORDER(Descending);
                    ToolTip = 'View filed contract quotes.';
                }
            }
        }
        area(processing)
        {
            action("&Make Contract")
            {
                ApplicationArea = Service;
                Caption = '&Make Contract';
                Image = MakeAgreement;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to create a service contract.';

                trigger OnAction()
                var
                    SignServContractDoc: Codeunit SignServContractDoc;
                begin
                    CurrPage.Update(true);
                    SignServContractDoc.SignContractQuote(Rec);
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintServiceContract(Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;
    end;
}

