page 12198 "Vendor Bill Withh. Tax"
{
    Caption = 'Vendor Bill Withh. Tax';
    PageType = Card;
    SourceTable = "Vendor Bill Withholding Tax";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Related Date"; "Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the vendor bill.';
                }
                field("Payment Date"; "Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the vendor bill withholding taxes are paid to the tax authority.';
                }
                field(Reason; Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code.';
                }
            }
            group("Withholding Tax")
            {
                Caption = 'Withholding Tax';
                field("Withholding Tax Code"; "Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding code that is applied to the vendor bill. ';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original transaction that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; "Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original transaction that is excluded from the withholding tax calculation based on exclusions allowed by law.';
                }
                field("Non Taxable Amount By Treaty"; "Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original transaction that is excluded from the withholding tax calculation based on residency. ';
                }
                field("Non Taxable %"; "Non Taxable %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of the original purchase that is not taxable because of provisions in the law.';
                }
                field("Non Taxable Amount"; "Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original transaction that is not taxable because of provisions in the law.';
                }
                field("Taxable Base"; "Taxable Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the vendor bill that is subject to withholding tax, after nontaxable and excluded amounts have been subtracted.';
                }
                field("Withholding Tax %"; "Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the vendor bill that is subject to withholding tax. ';
                }
                field("Withholding Tax Amount"; "Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of withholding tax that is due for the vendor bill. ';
                }
            }
            group("Social Security")
            {
                Caption = 'Social Security';
                field("Social Security Code"; "Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Social Security code that is applied to the vendor bill.';
                }
                field("Gross Amount"; "Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the vendor bill that is subject to Social Security withholding tax.';
                }
                field("Soc.Sec.Non Taxable Amount"; "Soc.Sec.Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the vendor bill that is excluded from Social Security tax based on provisions in the law.';
                }
                field("Contribution Base"; "Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the vendor bill that is subject to Social Security tax after the nontaxable amount has been subtracted.';
                }
                field("Social Security %"; "Social Security %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the vendor bill that is subject to Social Security tax.';
                }
                field("Total Social Security Amount"; "Total Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the vendor bill.';
                }
                field("Free-Lance %"; "Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the Social Security tax that is the responsibility of the independent contractor or vendor.';
                }
                field("Free-Lance Amount"; "Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax that is the responsibility of the vendor.';
                }
                field("Company Amount"; "Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of Social Security tax from the vendor bill that your company is liable for.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateForm
    end;

    trigger OnOpenPage()
    begin
        UpdateForm
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush;
    end;

    var
        Open: Boolean;
        Text11200: Label 'Vendor Bill Withh. Tax ';
        Text11201: Label 'Open';
        Text11202: Label 'Sent';

    [Scope('OnPrem')]
    procedure SetValues(OpenPara: Boolean)
    begin
        Open := OpenPara;
    end;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        CurrPage.Editable := Open;
        CurrPage.Caption := Text11200;
        if Open then
            CurrPage.Caption := CurrPage.Caption + Text11201
        else
            CurrPage.Caption := CurrPage.Caption + Text11202;
    end;

    local procedure OKOnPush()
    var
        VendBillLine: Record "Vendor Bill Line";
    begin
        if Open then
            if VendBillLine.Get("Vendor Bill List No.", "Line No.") then begin
                if VendBillLine."Remaining Amount" =
                   VendBillLine."Amount to Pay" + VendBillLine."Withholding Tax Amount" + "Old Free-Lance Amount"
                then
                    VendBillLine.Validate("Amount to Pay", (VendBillLine."Remaining Amount" - "Withholding Tax Amount" - "Free-Lance Amount"))
                else
                    VendBillLine.Validate("Amount to Pay", (VendBillLine."Amount to Pay" - "Withholding Tax Amount" - "Free-Lance Amount"));
                VendBillLine."Withholding Tax Amount" := "Withholding Tax Amount";
                VendBillLine."Social Security Amount" := "Total Social Security Amount";
                VendBillLine.Modify;
                "Old Free-Lance Amount" := "Free-Lance Amount";
                Modify;
            end;
    end;
}

