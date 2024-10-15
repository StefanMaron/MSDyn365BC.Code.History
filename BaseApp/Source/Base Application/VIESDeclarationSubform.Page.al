page 31067 "VIES Declaration Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "VIES Declaration Line";

    layout
    {
        area(content)
        {
            repeater(Control1220009)
            {
                ShowCaption = false;
                field("Trade Type"; "Trade Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies trade type for the declaration header (sales, purchases or both).';
                }
                field("Line Type"; "Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type (new, correction, or cancellation).';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies using European Union (EU) third-party trade service for the VIES declaration line.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        case "Trade Type" of
                            "Trade Type"::Sale:
                                begin
                                    Clear(CustList);
                                    CustList.LookupMode(true);
                                    Cust.SetCurrentKey("Country/Region Code");
                                    Cust.SetRange("Country/Region Code", "Country/Region Code");
                                    CustList.SetTableView(Cust);
                                    if CustList.RunModal = ACTION::LookupOK then begin
                                        CustList.GetRecord(Cust);
                                        Cust.TestField("VAT Registration No.");
                                        Validate("Country/Region Code", Cust."Country/Region Code");
                                        Validate("VAT Registration No.", Cust."VAT Registration No.");
                                    end;
                                end;
                            "Trade Type"::Purchase:
                                begin
                                    Clear(VendList);
                                    Vend.SetCurrentKey("Country/Region Code");
                                    Vend.SetRange("Country/Region Code", "Country/Region Code");
                                    VendList.SetTableView(Vend);
                                    VendList.LookupMode(true);
                                    if VendList.RunModal = ACTION::LookupOK then begin
                                        VendList.GetRecord(Vend);
                                        Vend.TestField("VAT Registration No.");
                                        Validate("Country/Region Code", Vend."Country/Region Code");
                                        Validate("VAT Registration No.", Vend."VAT Registration No.");
                                    end;
                                end;
                        end;
                    end;
                }
                field("Number of Supplies"; "Number of Supplies")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of supplies.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount of the entry in LCY.';

                    trigger OnDrillDown()
                    begin
                        DrillDownAmountLCY;
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Trade Role Type"; "Trade Role Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the trade role for the declaration line of direct trade, intermediate trade, or property movement.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        VIESDeclarationHdr: Record "VIES Declaration Header";
    begin
        if VIESDeclarationHdr.Get("VIES Declaration No.") then
            "Trade Type" := VIESDeclarationHdr."Trade Type";
    end;

    var
        Cust: Record Customer;
        Vend: Record Vendor;
        CustList: Page "Customer List";
        VendList: Page "Vendor List";
}

