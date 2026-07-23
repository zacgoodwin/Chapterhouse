# frozen_string_literal: true

module Dnd5Character
  module Races
    class DragonbornDecorator < ApplicationDecorator
      ANCESTRIES = {
        'draconic_ancestry_black' => {
          'damage_type' => { 'en' => 'acid' },
          'attack_type' => { 'en' => 'line' },
          'dist' => 30,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_blue' => {
          'damage_type' => { 'en' => 'lightning' },
          'attack_type' => { 'en' => 'line' },
          'dist' => 30,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_brass' => {
          'damage_type' => { 'en' => 'fire' },
          'attack_type' => { 'en' => 'line' },
          'dist' => 30,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_bronze' => {
          'damage_type' => { 'en' => 'lightning' },
          'attack_type' => { 'en' => 'line' },
          'dist' => 30,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_copper' => {
          'damage_type' => { 'en' => 'acid' },
          'attack_type' => { 'en' => 'line' },
          'dist' => 30,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_gold' => {
          'damage_type' => { 'en' => 'fire' },
          'attack_type' => { 'en' => 'cone' },
          'dist' => 15,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_green' => {
          'damage_type' => { 'en' => 'poison' },
          'attack_type' => { 'en' => 'cone' },
          'dist' => 15,
          'save_type' => { 'en' => 'Con' }
        },
        'draconic_ancestry_red' => {
          'damage_type' => { 'en' => 'fire' },
          'attack_type' => { 'en' => 'cone' },
          'dist' => 15,
          'save_type' => { 'en' => 'Dex' }
        },
        'draconic_ancestry_silver' => {
          'damage_type' => { 'en' => 'cold' },
          'attack_type' => { 'en' => 'cone' },
          'dist' => 15,
          'save_type' => { 'en' => 'Con' }
        },
        'draconic_ancestry_white' => {
          'damage_type' => { 'en' => 'cold' },
          'attack_type' => { 'en' => 'cone' },
          'dist' => 15,
          'save_type' => { 'en' => 'Con' }
        }
      }.freeze

      def resistance
        @resistance ||= __getobj__.resistance.push(ANCESTRIES.dig(draconic_ancestry, 'damage_type', 'en')).uniq
      end

      # rubocop: disable Metrics/AbcSize, Layout/LineLength, Metrics/MethodLength
      def features
        @features ||= begin
          result = __getobj__.features
          if draconic_ancestry
            ancestry_abilities = ANCESTRIES[draconic_ancestry]
            damage_type = translate(ancestry_abilities['damage_type'])
            attack_type = translate(ancestry_abilities['attack_type'])
            save_type = translate(ancestry_abilities['save_type'])
            save_dc = 8 + modifiers['con'] + proficiency_bonus

            result << {
              slug: 'breath_weapon',
              kind: 'static',
              title: translate({ en: 'Breath Weapon' }),
              description: translate({
                en: "Each creature in the area of the exhalation (#{attack_type}, #{ancestry_abilities['dist']}) must make a saving throw #{save_type} (DC #{save_dc}). A creature takes #{draconic_ancestry_damage} damage (#{damage_type}) on a failed save, and half as much damage on a successful one."
              }),
              limit: 1,
              limit_refresh: 'short_rest'
            }
          else
            result
          end
        end
      end
      # rubocop: enable Metrics/AbcSize, Layout/LineLength, Metrics/MethodLength

      private

      def draconic_ancestry
        @draconic_ancestry ||= selected_features['draconic_ancestry']
      end

      def draconic_ancestry_damage
        return '5d6' if level >= 16
        return '4d6' if level >= 11
        return '3d6' if level >= 6

        '2d6'
      end
    end
  end
end
