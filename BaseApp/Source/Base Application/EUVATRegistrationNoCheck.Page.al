page 1339 "EU VAT Registration No Check"
{
    Caption = 'EU VAT Registration No Check';
    PageType = StandardDialog;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(Control3)
            {
                ShowCaption = false;
                field("Region Country"; Region)
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = true;
                    TableRelation = "Country/Region" WHERE("EU Country/Region Code" = FILTER(<> ''));
                    ToolTip = 'Specifies the country/region.';

                    trigger OnValidate()
                    begin
                        DataTypeManagement.FindFieldByName(GlobalRecordRef, FieldRefVar, Customer.FieldName("Country/Region Code"));
                        FieldRefVar.Validate(Region);
                    end;
                }
                field("Vat Registration No"; VATRegNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vat Registration No.';

                    trigger OnValidate()
                    begin
                        DataTypeManagement.FindFieldByName(GlobalRecordRef, FieldRefVar, Customer.FieldName("VAT Registration No."));
                        FieldRefVar.Validate(VATRegNo);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        Customer: Record Customer;
        DataTypeManagement: Codeunit "Data Type Management";
        FieldRefVar: FieldRef;
        GlobalRecordRef: RecordRef;
        Region: Code[10];
        VATRegNo: Text;

    procedure SetRecordRef(RecordVariant: Variant)
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, GlobalRecordRef);
    end;

    procedure GetRecordRef(var RecordRef: RecordRef)
    begin
        RecordRef := GlobalRecordRef;
    end;
}

