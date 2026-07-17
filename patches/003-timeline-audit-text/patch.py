#!/usr/bin/env python3
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
t = path.read_text()
if "after_value_text" in t and "ORDER BY id SEPARATOR 0x1F" in t:
    print("already patched"); sys.exit(0)
t = t.replace("GROUP_CONCAT(field_name) as name,", "GROUP_CONCAT(field_name ORDER BY id SEPARATOR 0x1F) as name,", 1)
t = t.replace(
    "GROUP_CONCAT(after_value_string) as status,",
    "GROUP_CONCAT(COALESCE(NULLIF(after_value_string, ''), NULLIF(after_value_text, ''), '') ORDER BY id SEPARATOR 0x1F) as status,",
    1,
)
sep = "\\x1F"
t = re.sub(r"[ \t]*\$auditFields = explode\([^;]+;", lambda m: '                $auditFields = explode("'+sep+'", $record[\'name\'] ?? \'\');', t, count=1)
t = re.sub(r"[ \t]*\$auditFieldValues = explode\([^;]+;", lambda m: '                $auditFieldValues = explode("'+sep+'", $record[\'status\'] ?? \'\');', t, count=1)
old = """                    //present field value
                    $auditFieldValue = $auditFieldValues[$index] ?? '';

                    if ($field === 'assigned_user_id') {
                        // transform userid to username
                        /** @var User $user */
                        $user = BeanFactory::getBean('Users', $auditFieldValue);
                        $auditFieldValue = $user->user_name ?? '';
                    } else {
                        $auditFieldValue = $this->languageManager->getListLabel($legacyParentModule, $field, $auditFieldValue);
                    }

                    $auditDescription .= implode(" ", [$auditedFieldLabelKey, $auditFieldValue, '<br/>']);
"""
new = """                    // present field value (text audits use after_value_text)
                    $auditFieldValue = html_entity_decode(
                        (string) ($auditFieldValues[$index] ?? ''),
                        ENT_QUOTES | ENT_HTML5
                    );

                    if ($field === 'assigned_user_id') {
                        /** @var User $user */
                        $user = BeanFactory::getBean('Users', $auditFieldValue);
                        $auditFieldValue = $user->user_name ?? '';
                    } elseif (!empty($auditFieldDefinition['options'])) {
                        $auditFieldValue = $this->languageManager->getListLabel(
                            $legacyParentModule,
                            $field,
                            $auditFieldValue
                        );
                    }

                    $label = rtrim((string) $auditedFieldLabelKey, ': ');
                    $auditDescription .= htmlspecialchars($label, ENT_QUOTES, 'UTF-8')
                        . ': '
                        . htmlspecialchars($auditFieldValue, ENT_QUOTES, 'UTF-8')
                        . '<br/>';
"""
if old not in t:
    print("display loop missing", file=sys.stderr); sys.exit(1)
t = t.replace(old, new, 1)
assert t.count('{')==t.count('}')
path.write_text(t)
print("patched", path)
