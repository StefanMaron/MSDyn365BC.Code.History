table 5525 "Manufacturing User Template"
{
    Caption = 'Manufacturing User Template';
    ReplicateData = true;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Create Purchase Order"; Option)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Create Purchase Order';
            OptionCaption = ' ,Make Purch. Orders,Make Purch. Orders & Print,Copy to Req. Wksh';
            OptionMembers = " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        }
        field(3; "Create Production Order"; Option)
        {
            Caption = 'Create Production Order';
            OptionCaption = ' ,Planned,Firm Planned,Firm Planned & Print,Copy to Req. Wksh';
            OptionMembers = " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        }
        field(4; "Create Transfer Order"; Option)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Create Transfer Order';
            OptionCaption = ' ,Make Trans. Orders,Make Trans. Order & Print,Copy to Req. Wksh';
            OptionMembers = " ","Make Trans. Orders","Make Trans. Order & Print","Copy to Req. Wksh";
        }
        field(5; "Create Assembly Order"; Option)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Create Assembly Order';
            OptionCaption = ' ,Make Assembly Orders,Make Assembly Orders & Print';
            OptionMembers = " ","Make Assembly Orders","Make Assembly Orders & Print";
        }
        field(11; "Purchase Req. Wksh. Template"; Code[10])
        {
            Caption = 'Purchase Req. Wksh. Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(12; "Purchase Wksh. Name"; Code[10])
        {
            Caption = 'Purchase Wksh. Name';
            TableRelation = "Requisition Wksh. Name".Name WHERE("Worksheet Template Name" = FIELD("Purchase Req. Wksh. Template"));
        }
        field(15; "Prod. Req. Wksh. Template"; Code[10])
        {
            Caption = 'Prod. Req. Wksh. Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(16; "Prod. Wksh. Name"; Code[10])
        {
            Caption = 'Prod. Wksh. Name';
            TableRelation = "Requisition Wksh. Name".Name WHERE("Worksheet Template Name" = FIELD("Prod. Req. Wksh. Template"));
        }
        field(19; "Transfer Req. Wksh. Template"; Code[10])
        {
            Caption = 'Transfer Req. Wksh. Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(20; "Transfer Wksh. Name"; Code[10])
        {
            Caption = 'Transfer Wksh. Name';
            TableRelation = "Requisition Wksh. Name".Name WHERE("Worksheet Template Name" = FIELD("Transfer Req. Wksh. Template"));
        }
        field(21; "Make Orders"; Option)
        {
            Caption = 'Make Orders';
            OptionCaption = 'The Active Line,The Active Order,All Lines';
            OptionMembers = "The Active Line","The Active Order","All Lines";
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

