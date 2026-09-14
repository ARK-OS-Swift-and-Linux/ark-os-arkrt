/*
 * Copyright 2026 Aarav Ravindra Kharade
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ark_hi.c - ArkOS GTK3 Display App
// Draws a big "Hi" on screen using Roboto Bold font
// Compiled by aake, launched by Init with sandboxed permissions

#include <gtk/gtk.h>
#include <pango/pango.h>
#include <stdlib.h>
#include <string.h>

// Font configuration - loaded from the system font directory
#define ARKOS_FONT_FAMILY "Roboto"
#define ARKOS_FONT_SIZE_PX 120
#define ARKOS_DISPLAY_TEXT "Hi"

// Color palette (RGBA, 0.0-1.0)
typedef struct {
    double r, g, b, a;
} ArkColor;

static const ArkColor BG_COLOR   = {0.067, 0.067, 0.090, 1.0};  // Deep dark
static const ArkColor TEXT_COLOR = {0.400, 0.690, 1.000, 1.0};  // ArkOS blue
static const ArkColor GLOW_COLOR = {0.200, 0.400, 0.800, 0.15}; // Subtle glow

static gboolean on_draw(GtkWidget *widget, cairo_t *cr,
                         gpointer user_data __attribute__((unused))) {
    GtkAllocation alloc;
    gtk_widget_get_allocation(widget, &alloc);

    // Background
    cairo_set_source_rgba(cr, BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, BG_COLOR.a);
    cairo_paint(cr);

    // Build the Pango layout for the display text
    PangoLayout *layout = pango_cairo_create_layout(cr);

    char font_desc_str[128];
    snprintf(font_desc_str, sizeof(font_desc_str), "%s Bold %dpx",
             ARKOS_FONT_FAMILY, ARKOS_FONT_SIZE_PX);

    PangoFontDescription *font_desc =
        pango_font_description_from_string(font_desc_str);
    pango_layout_set_font_description(layout, font_desc);
    pango_layout_set_text(layout, ARKOS_DISPLAY_TEXT, -1);

    // Measure text to center it
    int text_w, text_h;
    pango_layout_get_pixel_size(layout, &text_w, &text_h);

    double x = (alloc.width - text_w) / 2.0;
    double y = (alloc.height - text_h) / 2.0;

    // Draw a soft glow behind the text (3 passes with increasing blur)
    for (int pass = 3; pass >= 1; pass--) {
        double offset = pass * 2.0;
        cairo_set_source_rgba(cr, GLOW_COLOR.r, GLOW_COLOR.g,
                              GLOW_COLOR.b, GLOW_COLOR.a / pass);
        cairo_move_to(cr, x - offset, y - offset);
        pango_cairo_show_layout(cr, layout);
    }

    // Draw the main text
    cairo_set_source_rgba(cr, TEXT_COLOR.r, TEXT_COLOR.g,
                          TEXT_COLOR.b, TEXT_COLOR.a);
    cairo_move_to(cr, x, y);
    pango_cairo_show_layout(cr, layout);

    // Cleanup — prevent memory leak
    pango_font_description_free(font_desc);
    g_object_unref(layout);

    return FALSE;
}

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "ArkOS");
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    GtkWidget *drawing_area = gtk_drawing_area_new();
    g_signal_connect(drawing_area, "draw", G_CALLBACK(on_draw), NULL);
    gtk_container_add(GTK_CONTAINER(window), drawing_area);

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}
