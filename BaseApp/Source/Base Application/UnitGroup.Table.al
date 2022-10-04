table 5400 "Unit Group"
{
    DataClassification = SystemMetadata;
    Caption = 'Unit Group';
#if CLEAN21
    Extensible = false;
#else
    ObsoleteState = Pending;
    ObsoleteReason = 'This table will be marked as not extensible.';
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Source Type"; Enum "Unit Group Source Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Type';
            Editable = false;
            NotBlank = true;
        }
        field(2; "Source Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Id';
            Editable = false;
            NotBlank = true;

            TableRelation = if ("Source Type" = const(Item)) Item.SystemId
            else
            "Resource".SystemId;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Source No.';
            Editable = false;
            NotBlank = true;

            TableRelation = if ("Source Type" = const(Item)) Item."No."
            else
            "Resource"."No.";
        }
        field(4; "Code"; Code[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Code';
            Editable = false;
            NotBlank = true;
            ObsoleteReason = 'This field is not used. Please use GetCode procedure instead.';
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#endif
        }
        field(5; "Source Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Name';
            Editable = false;

            TableRelation = if ("Source Type" = const(Item)) Item.Description
            else
            "Resource".Name;
            ObsoleteReason = 'This field is not used. Please use GetSourceName procedure instead.';
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#endif
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source Id")
        {
            Clustered = true;
        }
#if not CLEAN21
        key(Key2; "Code")
        {
        }
#endif
    }

    var
        ItemUnitGroupPrefixLbl: Label 'ITEM', Locked = true;
        ResourceUnitGroupPrefixLbl: Label 'RESOURCE', Locked = true;

    procedure GetCode(): Code[50]
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        case "Source Type" of
            "Source Type"::Item:
                if Item.GetBySystemId("Source Id") then
                    exit(ItemUnitGroupPrefixLbl + ' ' + Item."No." + ' ' + 'UOM GR');
            "Source Type"::Resource:
                if Resource.GetBySystemId("Source Id") then
                    exit(ResourceUnitGroupPrefixLbl + ' ' + Resource."No." + ' ' + 'UOM GR');
        end;
    end;

    procedure GetSourceName(): Text[100]
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        case "Source Type" of
            "Source Type"::Item:
                if Item.GetBySystemId("Source Id") then
                    exit(Item.Description);
            "Source Type"::Resource:
                if Resource.GetBySystemId("Source Id") then
                    exit(Resource.Name);
        end;
    end;
}