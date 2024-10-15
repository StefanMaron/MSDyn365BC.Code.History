#if not CLEAN18
page 31099 "Reverse Charge Subform"
{
    AutoSplitKey = true;
    Caption = 'Reverse Charge Subform';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                ObsoleteTag = '18.0';
                Visible = false;

                field("VAT Date"; VATDate)
                {
                    Caption = 'VAT Date';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT date. This date must be shown on the VAT statement.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Document Type"; DocumentType)
                {
                    Caption = 'Document Type';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer or vendor ledger entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Document No."; DocumentNo)
                {
                    Caption = 'Document No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer''s or vendor''s document.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Document Line No."; DocumentLineNo)
                {
                    Caption = 'Document Line No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of line of the sales or purchase document.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Country/Region Code"; CountryRegionCode)
                {
                    Caption = 'Country/Region Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("VAT Registration No."; VATRegistrationNo)
                {
                    Caption = 'VAT Registration No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field(Type; Type)
                {
                    Caption = 'Type';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of set advance link';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("No."; No)
                {
                    Caption = 'No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reverse charge.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field(Description; Description)
                {
                    Caption = 'Description';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of reverse charge.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Commodity Code"; CommodityCode)
                {
                    Caption = 'Commodity Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies code from reverse charge and control report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    Caption = 'Quantity';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies quantity of line in reverse charge';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Unit of Measure Code"; UnitofMeasureCode)
                {
                    Caption = 'Unit of Measure Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure code of the assembly item.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Document Quantity"; DocumentQuantity)
                {
                    Caption = 'Document Quantity';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the sales or purchase document.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Document Unit of Measure Code"; DocumentUnitofMeasureCode)
                {
                    Caption = 'Document Unit of Measure Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer or vendor ledger entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("VAT Base Amount (LCY)"; VATBaseAmountLCY)
                {
                    Caption = 'VAT Base Amount (LCY)';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT base amount of advance. The amount is in the local currency.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Reverse Charge Statement has been removed.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
            }
        }
    }

    var
        VATDate: Date;
        DocumentType: Integer;
        DocumentNo: Code[20];
        DocumentLineNo: Integer;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
        Type: Integer;
        No: Code[20];
        Description: Text[100];
        CommodityCode: Code[10];
        Quantity: Decimal;
        UnitofMeasureCode: Code[10];
        DocumentQuantity: Decimal;
        DocumentUnitofMeasureCode: Code[10];
        VATBaseAmountLCY: Decimal;
}
#endif