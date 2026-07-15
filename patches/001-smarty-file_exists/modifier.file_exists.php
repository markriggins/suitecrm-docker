<?php
/**
 * Patch 001 — Smarty modifier for file_exists.
 * SuiteCRM core templates (e.g. suite8 header.tpl) use {if file_exists(...)}.
 * Smarty 5 requires explicit registration; see patches/PATCHES.md.
 */
function smarty_modifier_file_exists($file)
{
    return file_exists((string) $file);
}
