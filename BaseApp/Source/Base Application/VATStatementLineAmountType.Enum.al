#if not CLEAN19
enum 258 "VAT Statement Line Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Amount") { Caption = 'Amount'; }
    value(2; "Base") { Caption = 'Base'; }
    value(3; "Unrealized Amount") { Caption = 'Unrealized Amount'; }
    value(4; "Unrealized Base") { Caption = 'Unrealized Base'; }
    value(5; "Adv. Base") { Caption = 'Adv. Base (Obsolete)'; ObsoleteState = Pending; ObsoleteReason = 'This value is discontinued and should no longer be used (Prolonged to support Advance Letter).'; ObsoleteTag = '17.0'; }
}
#endif